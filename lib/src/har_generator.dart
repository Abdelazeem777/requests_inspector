import 'dart:convert';

import 'package:dio/dio.dart';

import '../requests_inspector.dart';

class HarGenerator {
  const HarGenerator();

  String generate({
    required RequestDetails request,
    String? curlCommand,
  }) {
    final startedDateTime = request.sentTime.toUtc().toIso8601String();
    // We keep only start time in top-level page; end time is implied by timings
    final durationMs = (request.receivedTime == null)
        ? 0
        : request.receivedTime!
            .difference(request.sentTime)
            .inMilliseconds
            .clamp(0, 1 << 31);

    final requestHeaders = _normalizeHeadersMap(request.headers);
    final queryString = _normalizeQueryParams(request.queryParameters);
    final postData = _buildPostData(request);

    final Map<String, dynamic> har = {
      'log': {
        'version': '1.2',
        'creator': {
          'name': 'requests_inspector',
          'version': '5.1.1',
        },
        'pages': [
          {
            'startedDateTime': startedDateTime,
            'id': request.id,
            'title': request.requestName,
            'pageTimings': {
              'onLoad': durationMs,
            },
          }
        ],
        'entries': [
          {
            'pageref': request.id,
            'startedDateTime': startedDateTime,
            'time': durationMs,
            'request': {
              'method': request.requestMethod.name,
              'url': _composeUrl(request.url, queryString),
              'httpVersion': 'HTTP/1.1',
              'cookies': [],
              'headers': requestHeaders,
              'queryString': queryString,
              'postData': postData,
              'headersSize': -1,
              'bodySize': _bodySize(postData),
            },
            'response': {
              'status': request.statusCode ?? 0,
              'statusText': '',
              'httpVersion': 'HTTP/1.1',
              'cookies': [],
              'headers': [],
              'content': _buildResponseContent(request.responseBody),
              'redirectURL': '',
              'headersSize': -1,
              'bodySize': -1,
            },
            'cache': {},
            'timings': {
              'send': 0,
              'wait': durationMs,
              'receive': 0,
            },
            if (curlCommand != null && curlCommand.isNotEmpty)
              'comment': 'cURL: ' + curlCommand,
          }
        ],
      }
    };

    return const JsonEncoder.withIndent('  ').convert(har);
  }

  List<Map<String, dynamic>> _normalizeHeadersMap(dynamic headers) {
    if (headers is Map) {
      return headers.entries
          .where((e) => e.value != null)
          .map((e) => {
                'name': e.key.toString(),
                'value': e.value.toString(),
              })
          .toList();
    }
    return [];
  }

  List<Map<String, dynamic>> _normalizeQueryParams(dynamic params) {
    if (params is Map) {
      return params.entries
          .where((e) => e.value != null)
          .map((e) => {
                'name': e.key.toString(),
                'value': e.value.toString(),
              })
          .toList();
    }
    return [];
  }

  Map<String, dynamic>? _buildPostData(RequestDetails request) {
    final body = request.requestBody;
    if (body == null) return null;

    // Determine mimeType and text
    if (body is FormData) {
      final params = <Map<String, String>>[];
      for (final field in body.fields) {
        params.add({'name': field.key, 'value': field.value});
      }
      for (final file in body.files) {
        final filename = file.value.filename ?? 'file';
        params.add({'name': file.key, 'value': '@' + filename});
      }
      return {
        'mimeType': 'multipart/form-data',
        'params': params,
      };
    }

    if (body is Map || body is List) {
      return {
        'mimeType': 'application/json',
        'text': jsonEncode(body),
      };
    }

    // x-www-form-urlencoded
    final contentType = (request.headers is Map)
        ? ((request.headers as Map)['content-type'] ??
            (request.headers as Map)['Content-Type'] ??
            '')
        : '';
    if (contentType.toString().contains('application/x-www-form-urlencoded') &&
        body is Map) {
      final params = body.entries
          .map((e) => {'name': e.key.toString(), 'value': e.value.toString()})
          .toList();
      return {
        'mimeType': 'application/x-www-form-urlencoded',
        'params': params,
      };
    }

    return {
      'mimeType': 'text/plain',
      'text': body.toString(),
    };
  }

  Map<String, dynamic> _buildResponseContent(dynamic responseBody) {
    if (responseBody == null) {
      return {
        'size': 0,
        'mimeType': 'x-unknown',
        'text': '',
      };
    }
    if (responseBody is Map || responseBody is List) {
      final text = jsonEncode(responseBody);
      return {
        'size': utf8.encode(text).length,
        'mimeType': 'application/json',
        'text': text,
      };
    }
    final text = responseBody.toString();
    return {
      'size': utf8.encode(text).length,
      'mimeType': 'text/plain',
      'text': text,
    };
  }

  int _bodySize(Map<String, dynamic>? postData) {
    if (postData == null) return 0;
    if (postData['text'] is String) {
      return utf8.encode(postData['text'] as String).length;
    }
    if (postData['params'] is List) {
      // Rough estimate of params payload size
      final List<dynamic> params = List<dynamic>.from(postData['params']);
      return params.fold<int>(0, (int prev, dynamic e) {
        if (e is Map) {
          final name = e['name']?.toString() ?? '';
          final value = e['value']?.toString() ?? '';
          return prev + name.length + value.length + 2; // '=' or '&'
        }
        return prev;
      });
    }
    return -1;
  }

  String _composeUrl(String baseUrl, List<Map<String, dynamic>> q) {
    if (q.isEmpty) return baseUrl;
    final qp = q
        .map((e) =>
            Uri.encodeQueryComponent(e['name'].toString()) +
            '=' +
            Uri.encodeQueryComponent(e['value'].toString()))
        .join('&');
    if (baseUrl.contains('?')) return baseUrl + '&' + qp;
    return baseUrl + '?' + qp;
  }
}
