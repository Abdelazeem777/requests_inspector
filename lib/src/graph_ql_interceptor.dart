import 'dart:convert';

import 'package:hasura_connect/hasura_connect.dart';
import 'package:requests_inspector/requests_inspector.dart';

class GraphQlInterceptor extends Interceptor {
  Request? request;
  @override
  Future<void> onConnected(HasuraConnect connect) async {}

  @override
  Future onError(HasuraError error, HasuraConnect connect) async {
    InspectorController().addNewRequest(
      RequestDetails(
        requestName: error.request.query.variables?.entries.first.value,
        requestMethod: RequestMethod.POST,
        requestBody: error.request.query.toString(),
        headers: error.request.headers,
        url: connect.url,
        responseBody: error.message,
      ),
    );
    return error;
  }

  @override
  Future<Request> onRequest(Request request, HasuraConnect connect) async {
    request = request;
    return request;
  }

  @override
  Future onResponse(Response response, HasuraConnect connect) async {
    InspectorController().addNewRequest(
      RequestDetails(
        requestName: response.request.query.variables?.entries.first.value,
        requestMethod: RequestMethod.POST,
        requestBody: response.request.query.toString(),
        headers: response.request.headers,
        statusCode: response.statusCode,
        url: connect.url,
        responseBody: response.data,
      ),
    );
    return response;
  }

  @override
  Future<void> onSubscription(Request request, Snapshot snapshot) async {}

  @override
  Future<void> onTryAgain(HasuraConnect connect) async {}

  @override
  Future<void>? onDisconnected() {
    throw UnimplementedError();
  }
}
