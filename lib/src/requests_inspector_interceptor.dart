import 'package:dio/dio.dart';

import '../requests_inspector.dart';

class RequestsInspectorInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    InspectorController().addNewRequest(
      RequestDetails(
        requestMethod: RequestMethod.values
            .firstWhere((e) => e.name == response.requestOptions.method),
        url: response.requestOptions.path,
        statusCode: response.statusCode ?? 0,
        headers: response.requestOptions.headers,
        queryParameters: response.requestOptions.queryParameters,
        responseBody: response.data,
        sentTime: DateTime.now(),
      ),
    );
    super.onResponse(response, handler);
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    InspectorController().addNewRequest(
      RequestDetails(
        requestMethod: RequestMethod.values
            .firstWhere((e) => e.name == err.requestOptions.method),
        url: err.requestOptions.path,
        headers: err.requestOptions.headers,
        queryParameters: err.requestOptions.queryParameters,
        responseBody: err.message,
        sentTime: DateTime.now(),
      ),
    );
    super.onError(err, handler);
  }
}
