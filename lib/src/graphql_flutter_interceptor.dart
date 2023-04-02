import 'dart:async';
import 'dart:developer';
import 'package:graphql/client.dart';

import '../requests_inspector.dart';

class GraphQLFlutterInterceptor extends Link {
  final String url;

  GraphQLFlutterInterceptor(this.url);

  @override
  Stream<Response> request(Request request, [NextLink? forward]) {
    return HttpLink(url).request(request, forward).map((response) {
      InspectorController().addNewRequest(
        RequestDetails(
          requestName: request.operation.document.definitions.first.span?.text,
          requestMethod: RequestMethod.POST,
          requestBody: request.operation
              .toString()
              .split('DocumentNode("')[1]
              .split('"), operationName: null)')[0]
              .replaceAll(RegExp(r'__typename'), '')
              .replaceAll(RegExp(r'\\n'), ''),
          url: url,
          statusCode: (response.errors ?? []).isEmpty ? 200 : 400,
          responseBody: response.data,
        ),
      );
      return response;
    });
  }
}
