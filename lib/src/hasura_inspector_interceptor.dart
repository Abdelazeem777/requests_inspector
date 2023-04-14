import 'package:hasura_connect/hasura_connect.dart';
import 'package:requests_inspector/requests_inspector.dart';

class HasuraInspectorInterceptor extends Interceptor {
  @override
  Future<void> onConnected(HasuraConnect connect) async {}

  @override
  Future onError(HasuraError error, HasuraConnect connect) async {
    final request = error.request;
    InspectorController().addNewRequest(
      RequestDetails(
        requestName: request.query.variables?.entries.first.value,
        requestMethod: RequestMethod.POST,
        requestBody: request.query.toString(),
        headers: request.headers,
        url: connect.url,
        responseBody: error.message,
      ),
    );
    return request;
  }

  @override
  Future<Request> onRequest(Request request, _) async => request;

  @override
  Future onResponse(Response data, HasuraConnect connect) async {
    final request = data.request;
    InspectorController().addNewRequest(
      RequestDetails(
        requestName: request.query.variables?.entries.first.value,
        requestMethod: RequestMethod.POST,
        requestBody: request.query.toString(),
        headers: request.headers,
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
  Future<void>? onDisconnected() {}
}
