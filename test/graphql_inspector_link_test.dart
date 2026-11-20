import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphql/client.dart';
import 'package:http/http.dart' as http;
import 'package:requests_inspector/requests_inspector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GraphQLInspectorLink', () {
    late InspectorController inspectorController;

    setUp(() {
      inspectorController = InspectorController(
        enabled: true,
        showInspectorOn: ShowInspectorOn.LongPress,
      );
      inspectorController.clearAllRequests();
    });

    test(
      'logs failed HTTP GraphQL request when HttpLink throws HttpLinkServerException',
      () async {
        const errorMessage =
            'Cannot query field "oldPrice" on type "ProductVariantCustomFields".';
        final parsedResponse = Response(
          response: {
            'errors': [
              {'message': errorMessage},
            ],
          },
          errors: [GraphQLError(message: errorMessage)],
        );
        final failingLink = _ThrowingHttpLink(
          HttpLinkServerException(
            response: http.Response(
              jsonEncode(parsedResponse.response),
              400,
              headers: {'content-type': 'application/json'},
            ),
            parsedResponse: parsedResponse,
            statusCode: 400,
          ),
        );

        final inspectorLink = GraphQLInspectorLink(failingLink);
        final request = Request(
          operation: Operation(
            document: gql(r'''
              query products {
                products {
                  id
                }
              }
            '''),
            operationName: 'products',
          ),
          variables: const {
            'options': {
              'filter': {
                'facetValueId': {'eq': '1'},
              },
            },
          },
        );

        await expectLater(
          inspectorLink.request(request).toList(),
          throwsA(isA<HttpLinkServerException>()),
        );

        expect(inspectorController.requestsList, hasLength(1));

        final logged = inspectorController.requestsList.first;
        expect(logged.requestName, 'PRODUCTS');
        expect(logged.statusCode, 400);
        expect(logged.url, failingLink.uri.toString());
        expect(logged.requestMethod, RequestMethod.POST);
        expect(logged.graphqlRequestVars, request.variables);
        expect(logged.requestBody, contains('query products'));
        expect(logged.responseBody, parsedResponse.response);
      },
    );

    test('still logs successful HTTP GraphQL responses', () async {
      const responseBody = {
        'data': {
          'products': [
            {'id': '1'},
          ],
        },
      };
      final successLink = _SuccessHttpLink(
        Response(
          data: const {
            'products': [
              {'id': '1'},
            ],
          },
          response: responseBody,
          context: Context().withEntry(
            HttpLinkResponseContext(
              statusCode: 200,
              headers: {'content-type': 'application/json'},
            ),
          ),
        ),
      );

      final inspectorLink = GraphQLInspectorLink(successLink);
      final request = Request(
        operation: Operation(
          document: gql('query products { products { id } }'),
          operationName: 'products',
        ),
      );

      final responses = await inspectorLink.request(request).toList();

      expect(responses, hasLength(1));
      expect(inspectorController.requestsList, hasLength(1));
      expect(inspectorController.requestsList.first.statusCode, 200);
      expect(inspectorController.requestsList.first.responseBody, responseBody);
    });
  });
}

class _ThrowingHttpLink extends HttpLink {
  _ThrowingHttpLink(this._exception) : super('https://example.com/graphql');

  final HttpLinkServerException _exception;

  @override
  Stream<Response> request(Request request, [NextLink? forward]) {
    return Stream<Response>.error(_exception);
  }
}

class _SuccessHttpLink extends HttpLink {
  _SuccessHttpLink(this._response) : super('https://example.com/graphql');

  final Response _response;

  @override
  Stream<Response> request(Request request, [NextLink? forward]) async* {
    yield _response;
  }
}
