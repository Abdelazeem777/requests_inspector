import 'package:flutter_test/flutter_test.dart';
import 'package:requests_inspector/requests_inspector.dart';

import 'helpers/fakes.dart';

void main() {
  group('RequestDetails', () {
    test('derives an upper-case name from the last URL segment', () {
      final request = RequestDetails(
        requestMethod: RequestMethod.GET,
        url: 'https://api.example.com/v1/users?page=2',
      );

      expect(request.requestName, 'USERS');
    });

    test('upper-cases an explicit request name', () {
      final request = RequestDetails(
        requestName: 'getProfile',
        requestMethod: RequestMethod.GET,
        url: 'https://api.example.com/me',
      );

      expect(request.requestName, 'GETPROFILE');
    });

    test('defaults sentTime to now', () {
      final before = DateTime.now();
      final request = RequestDetails(
        requestMethod: RequestMethod.GET,
        url: 'https://api.example.com',
      );

      expect(request.sentTime.isBefore(before), isFalse);
      expect(request.sentTime.isAfter(DateTime.now()), isFalse);
    });

    test('id combines the endpoint without query and the sent time', () {
      final sentTime = DateTime.fromMillisecondsSinceEpoch(1700000000123);
      final request = RequestDetails(
        requestMethod: RequestMethod.GET,
        url: 'https://api.example.com/users?page=2',
        sentTime: sentTime,
      );

      expect(request.id, 'https://api.example.com/users-17000000001');
    });

    test('copyWith keeps unspecified fields and replaces the others', () {
      final original = sampleRequest(requestName: 'users');
      final later = original.sentTime.add(const Duration(seconds: 5));

      final copy = original.copyWith(
        requestMethod: RequestMethod.PUT,
        statusCode: 204,
        responseBody: 'done',
        receivedTime: later,
      );

      expect(copy.requestName, 'USERS');
      expect(copy.url, original.url);
      expect(copy.headers, original.headers);
      expect(copy.queryParameters, original.queryParameters);
      expect(copy.sentTime, original.sentTime);
      expect(copy.requestMethod, RequestMethod.PUT);
      expect(copy.statusCode, 204);
      expect(copy.responseBody, 'done');
      expect(copy.receivedTime, later);
      expect(original.copyWith(), original);
    });

    test('toMap drops null values and serialises times', () {
      final sentTime = DateTime.utc(2024, 1, 2, 3, 4, 5);
      final request = RequestDetails(
        requestMethod: RequestMethod.POST,
        url: 'https://api.example.com/users',
        requestBody: {'name': 'John'},
        sentTime: sentTime,
      );

      expect(request.toMap(), {
        'requestName': 'USERS',
        'requestMethod': 'POST',
        'url': 'https://api.example.com/users',
        'requestBody': {'name': 'John'},
        'sentTime': '2024-01-02T03:04:05.000Z',
      });
    });

    test('survives a JSON round trip', () {
      const headers = {'a': 'b'};
      const query = {'page': 1};
      const body = {'id': 1};
      final original = sampleRequest(
        headers: headers,
        queryParameters: query,
        responseBody: body,
        graphqlRequestVars: null,
        sentTime: DateTime.utc(2024, 5, 6, 7, 8, 9),
      );

      final decoded = RequestDetails.fromJson(original.toJson());

      expect(decoded.requestName, original.requestName);
      expect(decoded.requestMethod, original.requestMethod);
      expect(decoded.url, original.url);
      expect(decoded.statusCode, original.statusCode);
      expect(decoded.headers, headers);
      expect(decoded.queryParameters, query);
      expect(decoded.responseBody, body);
      expect(decoded.sentTime, original.sentTime);
      expect(decoded.receivedTime, original.receivedTime);
    });

    test('equality and hashCode follow the field values', () {
      final sentTime = DateTime(2024);
      RequestDetails build({int status = 200}) => RequestDetails(
        requestMethod: RequestMethod.GET,
        url: 'https://api.example.com/users',
        statusCode: status,
        sentTime: sentTime,
      );

      expect(build(), build());
      expect(build().hashCode, build().hashCode);
      expect(build(), isNot(build(status: 500)));
    });

    test('toString mentions the main fields', () {
      final text = sampleRequest().toString();

      expect(text, contains('requestMethod: RequestMethod.GET'));
      expect(text, contains('url: https://api.example.com/users'));
      expect(text, contains('statusCode: 200'));
    });
  });

  group('ResponseDetails', () {
    const response = ResponseDetails(
      statusCode: 200,
      url: 'https://api.example.com/users',
      headers: {'content-type': 'application/json'},
      responseBody: {'id': 1},
    );

    test('copyWith replaces only the given fields', () {
      final copy = response.copyWith(statusCode: 404, responseBody: 'missing');

      expect(copy.statusCode, 404);
      expect(copy.responseBody, 'missing');
      expect(copy.url, response.url);
      expect(copy.headers, response.headers);
    });

    test('toMap and toString expose every field', () {
      expect(response.toMap(), {
        'statusCode': 200,
        'url': 'https://api.example.com/users',
        'headers': {'content-type': 'application/json'},
        'responseBody': {'id': 1},
      });
      expect(response.toString(), contains('statusCode: 200'));
      expect(response.toString(), contains('responseBody: {id: 1}'));
    });
  });
}
