class ResponseDetails {
  final int statusCode;
  final dynamic headers;
  final dynamic responseBody;

  const ResponseDetails({
    required this.statusCode,
    this.headers,
    this.responseBody,
  });

  ResponseDetails copyWith({
    int? statusCode,
    dynamic headers,
    dynamic responseBody,
  }) {
    return ResponseDetails(
      statusCode: statusCode ?? this.statusCode,
      headers: headers ?? this.headers,
      responseBody: responseBody ?? this.responseBody,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'statusCode': statusCode,
      'headers': headers,
      'responseBody': responseBody,
    };
  }

  @override
  String toString() =>
      'ResponseDetails(statusCode: $statusCode, headers: $headers, responseBody: $responseBody)';
}
