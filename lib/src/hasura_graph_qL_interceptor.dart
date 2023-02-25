import 'package:hasura_connect/hasura_connect.dart';
import 'package:requests_inspector/requests_inspector.dart';

class HasuraGraphQLInterceptor extends Interceptor {
  Request? request;
  @override
  Future<void> onConnected(HasuraConnect connect) async {}

  @override
  Future onError(HasuraError request, HasuraConnect connect) async {
    InspectorController().addNewRequest(
      RequestDetails(
        requestName: request.request.query.variables?.entries.first.value,
        requestMethod: RequestMethod.POST,
        requestBody: request.request.query.toString(),
        headers: request.request.headers,
        url: connect.url,
        responseBody: request.message,
      ),
    );
    return request;
  }

  @override
  Future<Request> onRequest(Request request, HasuraConnect connect) async {
    request = request;
    return request;
  }

  @override
  Future onResponse(Response data, HasuraConnect connect) async {
    InspectorController().addNewRequest(
      RequestDetails(
        requestName: data.request.query.variables?.entries.first.value,
        requestMethod: RequestMethod.POST,
        requestBody: data.request.query.toString(),
        headers: data.request.headers,
        statusCode: data.statusCode,
        url: connect.url,
        responseBody: data.data,
      ),
    );
    return data;
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
