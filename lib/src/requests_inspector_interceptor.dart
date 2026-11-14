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
    if (requestDetails == null) return super.onRequest(options, handler);
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

    final method = _parseMethod(response.requestOptions.method);
    final urlAndQueryParMapEntry = _extractUrl(response.requestOptions);
    final url = urlAndQueryParMapEntry.key;
    final queryParameters = urlAndQueryParMapEntry.value;
    if (method != null) {
      InspectorController().addNewRequest(
        RequestDetails(
          requestMethod: method,
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
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final method = _parseMethod(err.requestOptions.method);
    final urlAndQueryParMapEntry = _extractUrl(err.requestOptions);
    final url = urlAndQueryParMapEntry.key;
    final queryParameters = urlAndQueryParMapEntry.value;
    if (method != null) {
      InspectorController().addNewRequest(
        RequestDetails(
          requestMethod: method,
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
    }
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

  /// Maps a Dio method string to [RequestMethod], or `null` when the method is
  /// not supported (e.g. TRACE, CONNECT or custom ones). The inspector must
  /// never break the host app's request, so such requests are just not
  /// inspected.
  RequestMethod? _parseMethod(String method) {
    for (final e in RequestMethod.values) {
      if (e.name == method.toUpperCase()) return e;
    }
    return null;
  }

  RequestDetails? _convertToRequestDetails(RequestOptions options) {
    final method = _parseMethod(options.method);
    if (method == null) return null;
    return RequestDetails(
      requestMethod: method,
      url: options.uri.toString(),
      headers: options.headers,
      queryParameters: options.queryParameters,
      requestBody: options.data,
      sentTime: DateTime.now(),
    );
  }

  RequestOptions _copyRequestToNewOptions(
    RequestOptions options,
    RequestDetails requestDetails,
  ) {
    // `requestDetails.url` already contains the query string, so it is split
    // off and merged into `queryParameters`; otherwise Dio would append the
    // query a second time (`?a=1&a=1`).
    final url = requestDetails.url;
    final queryStart = url.indexOf('?');
    final urlQuery = queryStart == -1
        ? const <String, dynamic>{}
        : (Uri.tryParse(url)?.queryParametersAll ?? const {}).map(
            (k, v) => MapEntry<String, dynamic>(k, v.length == 1 ? v.first : v),
          );
    final editedQuery = requestDetails.queryParameters;
    return options.copyWith(
      method: requestDetails.requestMethod.name,
      headers: requestDetails.headers,
      queryParameters: {
        ...urlQuery,
        if (editedQuery is Map) ...editedQuery.cast<String, dynamic>(),
      },
      data: requestDetails.requestBody,
      path: queryStart == -1 ? url : url.substring(0, queryStart),
      extra: {...options.extra, 'startTime': DateTime.now()},
    );
  }
}
