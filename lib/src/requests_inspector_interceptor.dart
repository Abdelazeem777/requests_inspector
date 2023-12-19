import 'package:dio/dio.dart';

import '../requests_inspector.dart';

class RequestsInspectorInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    options.extra['startTime'] = DateTime.now();
    return super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final urlAndQueryParMapEntry = _extractUrl(response.requestOptions);
    final url = urlAndQueryParMapEntry.key;
    final queryParameters = urlAndQueryParMapEntry.value;
    InspectorController().addNewRequest(
      RequestDetails(
        requestMethod: RequestMethod.values
            .firstWhere((e) => e.name == response.requestOptions.method),
        url: url,
        statusCode: response.statusCode ?? 0,
        headers: response.requestOptions.headers,
        queryParameters: queryParameters,
        requestBody: response.requestOptions.data,
        responseBody: response.data,
        sentTime: response.requestOptions.extra['startTime'],
        receivedTime: DateTime.now(),
      ),
    );
    super.onResponse(response, handler);
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    final urlAndQueryParMapEntry = _extractUrl(err.requestOptions);
    final url = urlAndQueryParMapEntry.key;
    final queryParameters = urlAndQueryParMapEntry.value;
    InspectorController().addNewRequest(
      RequestDetails(
        requestMethod: RequestMethod.values
            .firstWhere((e) => e.name == err.requestOptions.method),
        url: url,
        headers: err.requestOptions.headers,
        queryParameters: queryParameters,
        requestBody: err.requestOptions.data,
        responseBody: err.message,
        sentTime: err.requestOptions.extra['startTime'],
        receivedTime: DateTime.now(),
      ),
    );
    super.onError(err, handler);
  }

  MapEntry<String, Map<String, dynamic>> _extractUrl(
    RequestOptions requestOptions,
  ) {
    final splitUri = requestOptions.uri.toString().split('?');
    final baseUrl = splitUri.first;
    final builtInQuery = splitUri.length > 1 ? splitUri.last : null;
    final buildInQueryParamsList = builtInQuery?.split('&').map((e) {
      final split = e.split('=');
      return MapEntry(split.first, split.last);
    }).toList();
    final builtInQueryParams = buildInQueryParamsList == null
        ? null
        : Map.fromEntries(buildInQueryParamsList);
    final queryParameters = {
      ...?builtInQueryParams,
      ...requestOptions.queryParameters
    };

    return MapEntry(baseUrl, queryParameters);
  }
}
