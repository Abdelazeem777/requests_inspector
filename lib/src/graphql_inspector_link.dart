import 'dart:async';
import 'package:graphql/client.dart';
import 'package:gql/language.dart';

import '../requests_inspector.dart';

class GraphQLInspectorLink extends Link {
  GraphQLInspectorLink(this._httpLink);

  final HttpLink _httpLink;

  @override
  Stream<Response> request(Request request, [NextLink? forward]) async* {
    await for (final response in _httpLink.request(request, forward)) {
      final responseContext = response.context.entry<HttpLinkResponseContext>();
      InspectorController().addNewRequest(
        RequestDetails(
          requestName: request.operation.operationName,
          requestMethod: RequestMethod.POST,
          requestBody: printNode(request.operation.document)
              .replaceAll('\n', '')
              .replaceAll('__typename', ''),
          headers: responseContext?.headers,
          url: _httpLink.uri.toString(),
          responseBody: response.response,
          statusCode: responseContext?.statusCode ?? 0,
        ),
      );
      yield response;
    }
  }
}
