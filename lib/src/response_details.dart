class ResponseDetails {
  final int statusCode;
  final String url;
  final dynamic headers;
  final dynamic responseBody;

  const ResponseDetails({
    required this.statusCode,
    required this.url,
    this.headers,
    this.responseBody,
  });

  ResponseDetails copyWith({
    int? statusCode,
    String? url,
    dynamic headers,
    dynamic responseBody,
  }) {
    return ResponseDetails(
      url: url ?? this.url,
      statusCode: statusCode ?? this.statusCode,
      headers: headers ?? this.headers,
      responseBody: responseBody ?? this.responseBody,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'statusCode': statusCode,
      'url': url,
      'headers': headers,
      'responseBody': responseBody,
    };
  }

  @override
  String toString() =>
      'ResponseDetails(statusCode: $statusCode, url: $url, headers: $headers, responseBody: $responseBody)';
}
