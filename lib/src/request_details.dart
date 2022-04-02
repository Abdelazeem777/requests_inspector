import 'package:requests_inspector/requests_inspector.dart';

class RequestDetails {
  late final String? requestName;
  final RequestMethod requestMethod;
  final String url;
  final int? statusCode;
  final dynamic headers;
  final dynamic queryParameters;
  final dynamic requestBody;
  final dynamic responseBody;
  final DateTime sentTime;
  RequestDetails({
    String? requestName,
    required this.requestMethod,
    required this.url,
    this.statusCode,
    this.headers,
    this.queryParameters,
    this.requestBody,
    this.responseBody,
    required this.sentTime,
  }) {
    this.requestName = requestName ?? _extractName(url);
  }

  String _extractName(String url) {
    url = url.split('?').first;
    final name = url.split('/').last;
    return name.toUpperCase();
  }

  RequestDetails copyWith({
    String? requestName,
    RequestMethod? requestMethod,
    String? url,
    int? statusCode,
    headers,
    queryParameters,
    requestBody,
    responseBody,
    DateTime? sentTime,
  }) {
    return RequestDetails(
      requestName: requestName ?? this.requestName,
      requestMethod: requestMethod ?? this.requestMethod,
      url: url ?? this.url,
      statusCode: statusCode ?? this.statusCode,
      headers: headers ?? this.headers,
      queryParameters: queryParameters ?? this.queryParameters,
      requestBody: requestBody ?? this.requestBody,
      responseBody: responseBody ?? this.responseBody,
      sentTime: sentTime ?? this.sentTime,
    );
  }

  @override
  String toString() {
    return 'RequestDetails(requestName: $requestName, requestMethod: $requestMethod, url: $url, statusCode: $statusCode, headers: $headers, queryParameters: $queryParameters, requestBody: $requestBody, responseBody: $responseBody, sentTime: $sentTime)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RequestDetails &&
        other.requestName == requestName &&
        other.requestMethod == requestMethod &&
        other.url == url &&
        other.statusCode == statusCode &&
        other.headers == headers &&
        other.queryParameters == queryParameters &&
        other.requestBody == requestBody &&
        other.responseBody == responseBody &&
        other.sentTime == sentTime;
  }

  @override
  int get hashCode {
    return requestName.hashCode ^
        requestMethod.hashCode ^
        url.hashCode ^
        statusCode.hashCode ^
        headers.hashCode ^
        queryParameters.hashCode ^
        requestBody.hashCode ^
        responseBody.hashCode ^
        sentTime.hashCode;
  }
}
