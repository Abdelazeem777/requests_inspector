import 'dart:async';

import 'package:gql/language.dart';
import 'package:graphql/client.dart';

import '../requests_inspector.dart';

/// Wraps a GraphQL [Link] and mirrors each operation into [InspectorController].
///
/// [HttpLink] throws on HTTP errors (e.g. 400) instead of yielding a [Response],
/// so failures are logged in [catch] before the exception propagates.
class GraphQLInspectorLink extends Link {
  GraphQLInspectorLink(this._link);

  final Link _link;

  @override
  Stream<Response> request(Request request, [NextLink? forward]) {
    final link = _link;

    if (link is HttpLink) {
      return _handleHttpRequest(link, request, forward);
    } else if (link is WebSocketLink) {
      return _handleWebSocketRequest(link, request, forward);
    } else {
      return link.request(request, forward);
    }
  }

  /// Logs successful stream events and link-level failures for [HttpLink].
  Stream<Response> _handleHttpRequest(
    HttpLink link,
    Request request,
    NextLink? forward,
  ) async* {
    // Used when the link throws before any response is emitted.
    final requestHandlerStartedAt = DateTime.now();

    try {
      await for (final entry in link
          .request(request, forward)
          // Per-event timestamp: when this response arrived on the stream.
          .map((event) => MapEntry(DateTime.now(), event))) {
        final responseReceivedAt = entry.key;
        final response = entry.value;

        _logHttpExchange(
          request: request,
          link: link,
          sentTime: responseReceivedAt,
          statusCode:
              response.context.entry<HttpLinkResponseContext>()?.statusCode ??
                  0,
          headers: response.context.entry<HttpLinkResponseContext>()?.headers,
          responseBody: response.response,
        );
        yield response;
      }
    } on HttpLinkServerException catch (exception) {
      _logHttpServerException(
        request: request,
        link: link,
        sentTime: requestHandlerStartedAt,
        exception: exception,
      );
      rethrow;
    } on ServerException catch (exception) {
      _logHttpServerException(
        request: request,
        link: link,
        sentTime: requestHandlerStartedAt,
        exception: exception,
      );
      rethrow;
    } on HttpLinkParserException catch (exception) {
      _logHttpParserException(
        request: request,
        link: link,
        sentTime: requestHandlerStartedAt,
        exception: exception,
      );
      rethrow;
    }
  }

  Stream<Response> _handleWebSocketRequest(
    WebSocketLink link,
    Request request,
    NextLink? forward,
  ) async* {
    await for (final response in link.request(request, forward)) {
      InspectorController().addNewRequest(
        RequestDetails(
          requestName: request.operation.operationName ?? 'GraphQL',
          requestMethod: RequestMethod.WS,
          requestBody: printNode(
            request.operation.document,
          ).replaceAll('\n', '').replaceAll('__typename', ''),
          graphqlRequestVars: request.variables,
          url: link.url,
          responseBody: response.response,
          statusCode: 200,
        ),
      );
      yield response;
    }
  }

  /// Maps [ServerException] (and [HttpLinkServerException]) to inspector fields.
  void _logHttpServerException({
    required Request request,
    required HttpLink link,
    required DateTime sentTime,
    required ServerException exception,
  }) {
    final httpException =
        exception is HttpLinkServerException ? exception : null;
    _logHttpExchange(
      request: request,
      link: link,
      sentTime: sentTime,
      statusCode:
          exception.statusCode ?? httpException?.response.statusCode ?? 0,
      headers: httpException?.response.headers,
      responseBody:
          exception.parsedResponse?.response ?? httpException?.response.body,
    );
  }

  /// Maps a response body parse failure to inspector fields.
  void _logHttpParserException({
    required Request request,
    required HttpLink link,
    required DateTime sentTime,
    required HttpLinkParserException exception,
  }) {
    _logHttpExchange(
      request: request,
      link: link,
      sentTime: sentTime,
      statusCode: exception.response.statusCode,
      headers: exception.response.headers,
      responseBody: exception.response.body,
    );
  }

  /// Writes one HTTP GraphQL exchange to the inspector list.
  void _logHttpExchange({
    required Request request,
    required HttpLink link,

    /// Start time shown in the inspector (stream arrival or handler start).
    required DateTime sentTime,
    required int statusCode,
    Map<String, String>? headers,
    dynamic responseBody,
  }) {
    InspectorController().addNewRequest(
      RequestDetails(
        requestName: request.operation.operationName,
        requestMethod: RequestMethod.POST,
        requestBody: printNode(
          request.operation.document,
        ).replaceAll('\n', '').replaceAll('__typename', ''),
        graphqlRequestVars:
            request.variables.isEmpty ? null : request.variables,
        headers: headers,
        url: link.uri.toString(),
        responseBody: responseBody,
        statusCode: statusCode,
        sentTime: sentTime,
        receivedTime: DateTime.now(),
      ),
    );
  }
}
