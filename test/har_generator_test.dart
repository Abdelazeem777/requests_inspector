import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:requests_inspector/requests_inspector.dart';
import 'package:requests_inspector/src/har_generator.dart';

void main() {
  group('HarGenerator', () {
    test('generates valid minimal HAR for selected request', () {
      final now = DateTime.now();
      final request = RequestDetails(
        requestMethod: RequestMethod.POST,
        url: 'https://api.example.com/users',
        statusCode: 201,
        headers: {'content-type': 'application/json'},
        queryParameters: {'q': 'x'},
        requestBody: {'name': 'john'},
        responseBody: {'id': 1},
        sentTime: now,
        receivedTime: now.add(const Duration(milliseconds: 123)),
      );

      final har = const HarGenerator().generate(
        request: request,
        curlCommand: 'curl -X POST "https://api.example.com/users"',
      );

      final map = jsonDecode(har) as Map<String, dynamic>;
      expect(map['log'], isA<Map<String, dynamic>>());
      final entries = (map['log']['entries'] as List);
      expect(entries.length, 1);
      final entry = entries.first as Map<String, dynamic>;

      expect(entry['request']['method'], 'POST');
      expect((entry['request']['url'] as String),
          contains('https://api.example.com/users'));
      expect(entry['response']['status'], 201);
      expect(entry['time'], 123);
      expect(entry['timings']['wait'], 123);
      expect(entry['comment'], contains('cURL:'));
    });
  });
}
