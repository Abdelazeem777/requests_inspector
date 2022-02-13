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
        responseBody: response.data,
        sentTime: DateTime.now(),
      ),
    );
    super.onResponse(response, handler);
  }
}
