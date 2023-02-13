import 'package:hasura_connect/hasura_connect.dart';
import 'package:requests_inspector/requests_inspector.dart';

class GraphQlInterceptor extends Interceptor {
  Request? request;
  @override
  Future<void> onConnected(HasuraConnect connect) async {}

  @override
  Future onError(HasuraError request, HasuraConnect connect) async {
    InspectorController().addNewRequest(
      RequestDetails(
        requestName: request.request.query.variables?.entries.first.value,
        requestMethod: _convertFromRequestTypeToRequestMethod(request.request.type),
        requestBody: request.request.query,
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
        requestMethod: _convertFromRequestTypeToRequestMethod(data.request.type),
        requestBody: data.request.query,
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

  RequestMethod _convertFromRequestTypeToRequestMethod(RequestType requestType) =>
      RequestMethod.values.firstWhere((element) {
        return element.name.toLowerCase() == requestType.name.toLowerCase();
      }, orElse: () => RequestMethod.NONE);
}
