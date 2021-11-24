import 'dart:convert';

import 'package:flutter/foundation.dart';

class RequestDetails {
  final String? requestName;
  final String requestMethod;
  final String url;
  final int? statusCode;
  final dynamic headers;
  final dynamic requestBody;
  final dynamic responseBody;
  final DateTime sentTime;
  RequestDetails({
    this.requestName,
    required this.requestMethod,
    required this.url,
    this.statusCode,
    this.headers,
    this.requestBody,
    this.responseBody,
    required this.sentTime,
  });

  RequestDetails copyWith({
    String? requestName,
    String? requestMethod,
    String? url,
    int? statusCode,
    dynamic? headers,
    dynamic? requestBody,
    dynamic? responseBody,
    DateTime? sentTime,
  }) {
    return RequestDetails(
      requestName: requestName ?? this.requestName,
      requestMethod: requestMethod ?? this.requestMethod,
      url: url ?? this.url,
      statusCode: statusCode ?? this.statusCode,
      headers: headers ?? this.headers,
      requestBody: requestBody ?? this.requestBody,
      responseBody: responseBody ?? this.responseBody,
      sentTime: sentTime ?? this.sentTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requestName': requestName,
      'requestMethod': requestMethod,
      'url': url,
      'statusCode': statusCode,
      'headers': headers,
      'requestBody': requestBody,
      'responseBody': responseBody,
      'sentTime': sentTime.millisecondsSinceEpoch,
    };
  }

  factory RequestDetails.fromMap(Map<String, dynamic> map) {
    return RequestDetails(
      requestName: map['requestName'] != null ? map['requestName'] : null,
      requestMethod: map['requestMethod'],
      url: map['url'],
      statusCode: map['statusCode'] != null ? map['statusCode'] : null,
      headers: map['headers'],
      requestBody: map['requestBody'],
      responseBody: map['responseBody'],
      sentTime: DateTime.fromMillisecondsSinceEpoch(map['sentTime']),
    );
  }

  String toJson() => json.encode(toMap());

  factory RequestDetails.fromJson(String source) =>
      RequestDetails.fromMap(json.decode(source));

  @override
  String toString() {
    return 'RequestDetails(requestName: $requestName, requestMethod: $requestMethod, url: $url, statusCode: $statusCode, headers: $headers, requestBody: $requestBody, responseBody: $responseBody, sentTime: $sentTime)';
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
        requestBody.hashCode ^
        responseBody.hashCode ^
        sentTime.hashCode;
  }
}
