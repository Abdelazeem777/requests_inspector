import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:requests_inspector/requests_inspector.dart';
import 'package:requests_inspector/src/har_generator.dart';

import 'helpers/fakes.dart';

Map<String, dynamic> harFor(RequestDetails request, {String? curlCommand}) =>
    jsonDecode(
      const HarGenerator().generate(request: request, curlCommand: curlCommand),
    );

Map<String, dynamic> entryOf(Map<String, dynamic> har) =>
    (har['log']['entries'] as List).single as Map<String, dynamic>;

/// Checks the fields that HAR 1.2 marks as required, with their types.
/// http://www.softwareishard.com/blog/har-12-spec/
void expectValidHar12(Map<String, dynamic> har) {
  void expectNameValueList(Object? list) {
    expect(list, isA<List>());
    for (final item in list as List) {
      expect(item, {'name': isA<String>(), 'value': isA<String>()});
    }
  }

  final log = har['log'] as Map<String, dynamic>;
  expect(log['version'], '1.2');
  expect(log['creator'], {'name': isA<String>(), 'version': isA<String>()});

  final pageIds = <String>{};
  for (final page in log['pages'] as List) {
    expect(DateTime.tryParse(page['startedDateTime']), isNotNull);
    expect(page['id'], isA<String>());
    expect(page['title'], isA<String>());
    expect(page['pageTimings'], isA<Map>());
    pageIds.add(page['id']);
  }

  final entries = log['entries'] as List;
  expect(entries, isNotEmpty);
  for (final entry in entries.cast<Map<String, dynamic>>()) {
    expect(pageIds, contains(entry['pageref']));
    expect(DateTime.tryParse(entry['startedDateTime'])?.isUtc, isTrue);
    expect(entry['time'], isA<num>().having((t) => t, 'time', isNonNegative));
    expect(entry['cache'], isA<Map>());
    for (final timing in ['send', 'wait', 'receive']) {
      expect(entry['timings'][timing], isA<num>(), reason: timing);
    }

    final request = entry['request'] as Map<String, dynamic>;
    expect(request['method'], isA<String>());
    expect(Uri.parse(request['url']).isAbsolute, isTrue);
    expect(request['httpVersion'], isA<String>());
    expect(request['cookies'], isA<List>());
    expectNameValueList(request['headers']);
    expectNameValueList(request['queryString']);
    expect(request['headersSize'], isA<int>());
    expect(request['bodySize'], isA<int>());
    if (request.containsKey('postData')) {
      final postData = request['postData'];
      expect(postData, isA<Map>(), reason: 'postData must be an object');
      expect(postData['mimeType'], isA<String>());
      expect(
        postData['text'] is String || postData['params'] is List,
        isTrue,
        reason: 'postData needs text or params',
      );
    }

    final response = entry['response'] as Map<String, dynamic>;
    expect(response['status'], isA<int>());
    expect(response['statusText'], isA<String>());
    expect(response['httpVersion'], isA<String>());
    expect(response['cookies'], isA<List>());
    expectNameValueList(response['headers']);
    expect(response['content']['size'], isA<int>());
    expect(response['content']['mimeType'], isA<String>());
    expect(response['redirectURL'], isA<String>());
    expect(response['headersSize'], isA<int>());
    expect(response['bodySize'], isA<int>());
  }
}

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
      expect(
        (entry['request']['url'] as String),
        contains('https://api.example.com/users'),
      );
      expect(entry['response']['status'], 201);
      expect(entry['time'], 123);
      expect(entry['timings']['wait'], 123);
      expect(entry['comment'], contains('cURL:'));
    });

    test('produces the fields HAR 1.2 requires', () {
      final har = harFor(
        sampleRequest(
          requestMethod: RequestMethod.POST,
          requestBody: {'name': 'John'},
        ),
        curlCommand: 'curl -X POST "https://api.example.com/users"',
      );

      expectValidHar12(har);
      expect(har['log']['creator']['name'], 'requests_inspector');
    });

    test(
      'produces valid HAR 1.2 for a request without a body',
      () => expectValidHar12(harFor(sampleRequest(requestBody: null))),
      skip:
          'Known bug: postData is emitted as null when there is no body; '
          'HAR 1.2 expects the optional object to be omitted.',
    );

    test(
      'reports the package version as the creator version',
      () {
        final pubspec = File('pubspec.yaml').readAsStringSync();
        final version = RegExp(
          r'^version:\s*(\S+)',
          multiLine: true,
        ).firstMatch(pubspec)!;

        expect(
          harFor(sampleRequest())['log']['creator']['version'],
          version.group(1),
        );
      },
      skip:
          "Known bug: creator.version is hard-coded to '5.1.1' in "
          'har_generator.dart.',
    );

    test('uses the request id and name for the page', () {
      final request = sampleRequest();
      final har = harFor(request);
      final page = (har['log']['pages'] as List).single;

      expect(page['id'], request.id);
      expect(page['title'], request.requestName);
      expect(entryOf(har)['pageref'], request.id);
      expect(
        entryOf(har)['startedDateTime'],
        request.sentTime.toUtc().toIso8601String(),
      );
    });

    test('adds query parameters to the URL and to queryString', () {
      final entry = entryOf(
        harFor(
          sampleRequest(
            url: 'https://api.example.com/search',
            queryParameters: {'q': 'a b', 'page': 2, 'skip': null},
          ),
        ),
      );

      expect(
        entry['request']['url'],
        'https://api.example.com/search?q=a+b&page=2',
      );
      expect(entry['request']['queryString'], [
        {'name': 'q', 'value': 'a b'},
        {'name': 'page', 'value': '2'},
      ]);
    });

    test('appends query parameters to a URL that already has a query', () {
      final entry = entryOf(
        harFor(
          sampleRequest(
            url: 'https://api.example.com/search?lang=en',
            queryParameters: {'q': 'x'},
          ),
        ),
      );

      expect(
        entry['request']['url'],
        'https://api.example.com/search?lang=en&q=x',
      );
    });

    test('lists request headers and drops null values', () {
      final entry = entryOf(
        harFor(
          sampleRequest(
            headers: {'accept': 'application/json', 'x-null': null, 'x-num': 1},
          ),
        ),
      );

      expect(entry['request']['headers'], [
        {'name': 'accept', 'value': 'application/json'},
        {'name': 'x-num', 'value': '1'},
      ]);
      expect(
        entryOf(
          harFor(sampleRequest(headers: 'not a map')),
        )['request']['headers'],
        isEmpty,
      );
    });

    test('encodes Map and List bodies as JSON postData', () {
      final mapEntry = entryOf(
        harFor(
          sampleRequest(
            requestMethod: RequestMethod.POST,
            requestBody: {'name': 'Jörg'},
          ),
        ),
      );
      expect(mapEntry['request']['postData'], {
        'mimeType': 'application/json',
        'text': '{"name":"Jörg"}',
      });
      expect(
        mapEntry['request']['bodySize'],
        utf8.encode('{"name":"Jörg"}').length,
      );

      final listEntry = entryOf(
        harFor(
          sampleRequest(requestMethod: RequestMethod.POST, requestBody: [1, 2]),
        ),
      );
      expect(listEntry['request']['postData']['text'], '[1,2]');
    });

    test('keeps the JSON types of body values (uses the raw bodies)', () {
      const body = {
        'active': true,
        'n': 1,
        'd': 1.5,
        'x': null,
        'nested': {'off': false},
      };
      final entry = entryOf(
        harFor(
          sampleRequest(
            requestMethod: RequestMethod.POST,
            requestBody: body,
            responseBody: body,
          ),
        ),
      );

      expect(entry['request']['postData']['text'], jsonEncode(body));
      expect(entry['response']['content']['text'], jsonEncode(body));
    });

    test('encodes FormData as multipart params', () {
      final formData = FormData.fromMap({'name': 'John'})
        ..files.add(
          MapEntry(
            'avatar',
            MultipartFile.fromString('bytes', filename: 'me.png'),
          ),
        )
        ..files.add(MapEntry('blob', MultipartFile.fromString('bytes')));

      final entry = entryOf(
        harFor(
          sampleRequest(
            requestMethod: RequestMethod.POST,
            requestBody: formData,
          ),
        ),
      );

      expect(entry['request']['postData'], {
        'mimeType': 'multipart/form-data',
        'params': [
          {'name': 'name', 'value': 'John'},
          {'name': 'avatar', 'value': '@me.png'},
          {'name': 'blob', 'value': '@file'},
        ],
      });
      expect(entry['request']['bodySize'], greaterThan(0));
    });

    test('encodes other bodies as text/plain', () {
      final entry = entryOf(
        harFor(
          sampleRequest(
            requestMethod: RequestMethod.POST,
            requestBody: 'raw body',
          ),
        ),
      );

      expect(entry['request']['postData'], {
        'mimeType': 'text/plain',
        'text': 'raw body',
      });
      expect(entry['request']['bodySize'], 8);
    });

    test(
      'encodes x-www-form-urlencoded Map bodies as params',
      () {
        final entry = entryOf(
          harFor(
            sampleRequest(
              requestMethod: RequestMethod.POST,
              headers: {'content-type': 'application/x-www-form-urlencoded'},
              requestBody: {'name': 'John'},
            ),
          ),
        );

        expect(entry['request']['postData'], {
          'mimeType': 'application/x-www-form-urlencoded',
          'params': [
            {'name': 'name', 'value': 'John'},
          ],
        });
      },
      skip:
          'Known bug: the `body is Map` JSON branch runs first, so the '
          'x-www-form-urlencoded branch in _buildPostData is unreachable.',
    );

    test('describes the response content', () {
      Map<String, dynamic> contentFor(dynamic body) => entryOf(
        harFor(sampleRequest(responseBody: body)),
      )['response']['content'];

      expect(contentFor({'id': 1}), {
        'size': 8,
        'mimeType': 'application/json',
        'text': '{"id":1}',
      });
      expect(contentFor([1])['mimeType'], 'application/json');
      expect(contentFor('héllo'), {
        'size': 6,
        'mimeType': 'text/plain',
        'text': 'héllo',
      });
      expect(contentFor(null), {
        'size': 0,
        'mimeType': 'x-unknown',
        'text': '',
      });
    });

    test('uses 0 ms when the duration is unknown or negative', () {
      final sent = DateTime(2024);
      final pending = RequestDetails(
        requestMethod: RequestMethod.GET,
        url: 'https://api.example.com/users',
        sentTime: sent,
      );
      final backwards = sampleRequest(
        sentTime: sent,
        receivedTime: sent.subtract(const Duration(seconds: 1)),
      );

      for (final request in [pending, backwards]) {
        final entry = entryOf(harFor(request));
        expect(entry['time'], 0);
        expect(entry['timings']['wait'], 0);
      }
    });

    test('only adds the cURL comment when a command is given', () {
      expect(entryOf(harFor(sampleRequest())), isNot(contains('comment')));
      expect(
        entryOf(harFor(sampleRequest(), curlCommand: '')),
        isNot(contains('comment')),
      );
      expect(
        entryOf(harFor(sampleRequest(), curlCommand: 'curl x'))['comment'],
        'cURL: curl x',
      );
    });
  });
}
