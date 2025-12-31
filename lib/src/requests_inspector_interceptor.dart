import 'package:dio/dio.dart';

import '../requests_inspector.dart';

class RequestsInspectorInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.extra['startTime'] = DateTime.now();

    if (!InspectorController().requestStopperEnabled)
      return super.onRequest(options, handler);

    final requestDetails = _convertToRequestDetails(options);
    final newRequestDetails = await InspectorController().editRequest(
      requestDetails,
    );

    if (newRequestDetails == null) return super.onRequest(options, handler);

    final newOptions = _copyRequestToNewOptions(options, newRequestDetails);
    return super.onRequest(newOptions, handler);
  }

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    final dateTime = DateTime.now();

    if (InspectorController().responseStopperEnabled) {
      final url = _extractUrl(response.requestOptions).key;
      final oldResponseData = ResponseDetails(
        url: url,
        statusCode: response.statusCode ?? 0,
        headers: response.headers.map,
        responseBody: response.data,
      );

      final newResponseData = await InspectorController().editResponse(
        oldResponseData,
      );

      if (newResponseData != null) {
        response.data = newResponseData.responseBody;
        response.statusCode = newResponseData.statusCode;
        // Update headers if they were modified
        if (newResponseData.headers != null) {
          response.headers.clear();
          if (newResponseData.headers is Map) {
            (newResponseData.headers as Map).forEach((key, value) {
              response.headers.add(key.toString(), value.toString());
            });
          }
        }
      }
    }

    final urlAndQueryParMapEntry = _extractUrl(response.requestOptions);
    final url = urlAndQueryParMapEntry.key;
    final queryParameters = urlAndQueryParMapEntry.value;
    InspectorController().addNewRequest(
      RequestDetails(
        requestMethod: RequestMethod.values.firstWhere(
          (e) => e.name == response.requestOptions.method,
        ),
        url: url,
        statusCode: response.statusCode ?? 0,
        headers: response.requestOptions.headers,
        queryParameters: queryParameters,
        requestBody: response.requestOptions.data,
        responseBody: response.data,
        sentTime: response.requestOptions.extra['startTime'],
        receivedTime: dateTime,
      ),
    );
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final urlAndQueryParMapEntry = _extractUrl(err.requestOptions);
    final url = urlAndQueryParMapEntry.key;
    final queryParameters = urlAndQueryParMapEntry.value;
    InspectorController().addNewRequest(
      RequestDetails(
        requestMethod: RequestMethod.values.firstWhere(
          (e) => e.name == err.requestOptions.method,
        ),
        url: url,
        statusCode: err.response?.statusCode ?? 0,
        headers: err.requestOptions.headers,
        queryParameters: queryParameters,
        requestBody: err.requestOptions.data,
        responseBody: err.response?.data ?? err.message,
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
      ...requestOptions.queryParameters,
    };

    return MapEntry(baseUrl, queryParameters);
  }

  RequestDetails _convertToRequestDetails(RequestOptions options) =>
      RequestDetails(
        requestMethod: RequestMethod.values.firstWhere(
          (e) => e.name == options.method,
        ),
        url: options.uri.toString(),
        headers: options.headers,
        queryParameters: options.queryParameters,
        requestBody: options.data,
        sentTime: DateTime.now(),
      );

  RequestOptions _copyRequestToNewOptions(
    RequestOptions options,
    RequestDetails requestDetails,
  ) =>
      options.copyWith(
        method: requestDetails.requestMethod.name,
        headers: requestDetails.headers,
        queryParameters: requestDetails.queryParameters,
        data: requestDetails.requestBody,
        path: requestDetails.url,
        extra: {...options.extra, 'startTime': DateTime.now()},
      );
}
