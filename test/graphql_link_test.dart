import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphql/client.dart';
import 'package:requests_inspector/requests_inspector.dart';

/// An [HttpLink] that answers from memory instead of the network.
class _FakeHttpLink extends HttpLink {
  _FakeHttpLink(this._respond) : super('https://example.com/graphql');

  final Stream<Response> Function(Request request) _respond;

  @override
  Stream<Response> request(Request request, [NextLink? forward]) =>
      _respond(request);
}

/// A [WebSocketLink] that never opens a socket.
class _FakeWebSocketLink extends WebSocketLink {
  _FakeWebSocketLink(this._responses) : super('wss://example.com/graphql');

  final List<Response> _responses;

  @override
  Stream<Response> request(Request request, [NextLink? forward]) =>
      Stream.fromIterable(_responses);
}

/// Any other terminating link.
class _FakeLink extends Link {
  _FakeLink(this._response);

  final Response _response;

  @override
  Stream<Response> request(Request request, [NextLink? forward]) =>
      Stream.value(_response);
}

Response _response(
  Map<String, dynamic> body, {
  int statusCode = 200,
  Map<String, String> headers = const {'content-type': 'application/json'},
}) =>
    Response(
      data: body['data'] as Map<String, dynamic>?,
      response: body,
      context: const Context().withEntry(
        HttpLinkResponseContext(statusCode: statusCode, headers: headers),
      ),
    );

Request _request({
  String document = 'query products { products { id __typename } }',
  String? operationName = 'products',
  Map<String, dynamic> variables = const {},
}) =>
    Request(
      operation: Operation(
        document: gql(document),
        operationName: operationName,
      ),
      variables: variables,
    );

void main() {
  late InspectorController controller;

  setUp(() {
    controller = InspectorController(
      enabled: true,
      showInspectorOn: ShowInspectorOn.LongPress,
    );
  });

  tearDown(() => controller.dispose());

  const body = {
    'data': {
      'products': [
        {'id': '1'},
      ],
    },
  };

  group('GraphQLInspectorLink over HttpLink', () {
    test('passes the response through and logs it', () async {
      final link = GraphQLInspectorLink(
        _FakeHttpLink((_) => Stream.value(_response(body))),
      );

      final responses =
          await link.request(_request(variables: const {'first': 10})).toList();

      expect(responses.single.response, body);
      final logged = controller.requestsList.single;
      expect(logged.requestName, 'PRODUCTS');
      expect(logged.requestMethod, RequestMethod.POST);
      expect(logged.url, 'https://example.com/graphql');
      expect(logged.statusCode, 200);
      expect(logged.responseBody, body);
      expect(logged.graphqlRequestVars, {'first': 10});
      expect(logged.headers, {'content-type': 'application/json'});
      expect(logged.requestBody, contains('query products'));
      expect(logged.requestBody, isNot(contains('\n')));
      expect(logged.requestBody, isNot(contains('__typename')));
    });

    test('logs empty variables as null and missing context as status 0',
        () async {
      final link = GraphQLInspectorLink(
        _FakeHttpLink((_) => Stream.value(const Response(response: body))),
      );

      await link.request(_request()).drain<void>();

      final logged = controller.requestsList.single;
      expect(logged.graphqlRequestVars, isNull);
      expect(logged.statusCode, 0);
      expect(logged.headers, isNull);
    });

    test('logs every response of a multi-response stream', () async {
      final link = GraphQLInspectorLink(_FakeHttpLink(
        (_) => Stream.fromIterable([_response(body), _response(body)]),
      ));

      await link.request(_request()).drain<void>();

      expect(controller.requestsList, hasLength(2));
    });

    test(
      'records the time the request was sent, not when it was answered',
      () async {
        const latency = Duration(milliseconds: 100);
        final link = GraphQLInspectorLink(_FakeHttpLink((_) async* {
          await Future<void>.delayed(latency);
          yield _response(body);
        }));

        await link.request(_request()).drain<void>();

        final logged = controller.requestsList.single;
        expect(
          logged.receivedTime!.difference(logged.sentTime),
          greaterThanOrEqualTo(latency),
        );
      },
      skip: 'Known bug: sentTime is taken in .map() when the response '
          'arrives, so every GraphQL request shows a ~0 ms duration '
          '(graphql_inspector_link.dart:30). Not fixed by PR #70.',
    );

    test(
      'logs a failed request before rethrowing',
      () async {
        final error = ServerException(
          statusCode: 400,
          parsedResponse: const Response(response: {
            'errors': [
              {'message': 'Cannot query field "price"'},
            ],
          }),
        );
        final link =
            GraphQLInspectorLink(_FakeHttpLink((_) => Stream.error(error)));

        await expectLater(
          link.request(_request()).toList(),
          throwsA(same(error)),
        );

        final logged = controller.requestsList.single;
        expect(logged.statusCode, 400);
        expect(logged.responseBody, error.parsedResponse!.response);
      },
      skip: 'Known bug: failed HttpLink requests (ServerException / '
          'HttpLinkServerException) are not logged. Issue #69, PR #70.',
    );
  });

  group('GraphQLInspectorLink over WebSocketLink', () {
    test('logs each event as a WS request', () async {
      final link = GraphQLInspectorLink(
        _FakeWebSocketLink([_response(body), _response(body)]),
      );

      await link
          .request(_request(
            document: 'subscription { onProduct { id } }',
            operationName: null,
            variables: const {'a': 1},
          ))
          .drain<void>();

      expect(controller.requestsList, hasLength(2));
      final logged = controller.requestsList.first;
      expect(logged.requestName, 'GRAPHQL');
      expect(logged.requestMethod, RequestMethod.WS);
      expect(logged.url, 'wss://example.com/graphql');
      expect(logged.statusCode, 200);
      expect(logged.graphqlRequestVars, {'a': 1});
      expect(logged.responseBody, body);
      expect(logged.requestBody, contains('subscription'));
    });
  });

  test('other links are passed through without logging', () async {
    final link = GraphQLInspectorLink(_FakeLink(_response(body)));

    final responses = await link.request(_request()).toList();

    expect(responses.single.response, body);
    expect(controller.requestsList, isEmpty);
  });
}
