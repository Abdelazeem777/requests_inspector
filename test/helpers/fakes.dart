import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:requests_inspector/requests_inspector.dart';

/// A Dio adapter that never touches the network.
///
/// Every request is recorded in [requests] and answered by [handler].
class FakeHttpClientAdapter implements HttpClientAdapter {
  FakeHttpClientAdapter(this.handler);

  /// Answers every request with [body] (JSON-encoded unless it is a String).
  factory FakeHttpClientAdapter.json(Object? body, {int statusCode = 200}) =>
      FakeHttpClientAdapter((_) => jsonBody(body, statusCode: statusCode));

  final Future<ResponseBody> Function(RequestOptions options) handler;
  final requests = <RequestOptions>[];

  static Future<ResponseBody> jsonBody(Object? body, {int statusCode = 200}) =>
      Future.value(ResponseBody.fromString(
        body is String ? body : jsonEncode(body),
        statusCode,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ));

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

/// A [Dio] with the inspector interceptor and a fake adapter.
Dio inspectedDio(HttpClientAdapter adapter, {BaseOptions? options}) => Dio(
      options ?? BaseOptions(baseUrl: 'https://api.example.com'),
    )
      ..httpClientAdapter = adapter
      ..interceptors.add(RequestsInspectorInterceptor());

/// A fully populated [RequestDetails] with fixed times.
RequestDetails sampleRequest({
  String? requestName,
  RequestMethod requestMethod = RequestMethod.GET,
  String url = 'https://api.example.com/users',
  int? statusCode = 200,
  dynamic headers = const {'content-type': 'application/json'},
  dynamic queryParameters = const {'page': 1},
  dynamic requestBody,
  dynamic graphqlRequestVars,
  dynamic responseBody = const {'id': 1, 'name': 'John'},
  DateTime? sentTime,
  DateTime? receivedTime,
}) {
  final sent = sentTime ?? DateTime(2024, 1, 2, 10, 20, 30);
  return RequestDetails(
    requestName: requestName,
    requestMethod: requestMethod,
    url: url,
    statusCode: statusCode,
    headers: headers,
    queryParameters: queryParameters,
    requestBody: requestBody,
    graphqlRequestVars: graphqlRequestVars,
    responseBody: responseBody,
    sentTime: sent,
    receivedTime: receivedTime ?? sent.add(const Duration(milliseconds: 250)),
  );
}
