import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:requests_inspector/requests_inspector.dart';
import 'package:requests_inspector/src/curl_command_generator.dart';

import 'helpers/fakes.dart';
import 'helpers/shell_words.dart';

String curlFor(RequestDetails request) =>
    CurlCommandGenerator(request).generate();

/// The arguments the shell would pass to curl for [request].
List<String> curlArgs(RequestDetails request) => shellWords(curlFor(request));

RequestDetails bare({
  RequestMethod method = RequestMethod.GET,
  String url = 'https://api.example.com/users',
  dynamic headers,
  dynamic queryParameters,
  dynamic body,
}) =>
    sampleRequest(
      requestMethod: method,
      url: url,
      headers: headers,
      queryParameters: queryParameters,
      requestBody: body,
    );

void main() {
  group('CurlCommandGenerator', () {
    test('builds a minimal GET command', () {
      expect(
        curlFor(bare()),
        'curl -X GET "https://api.example.com/users" -L -k ',
      );
      expect(curlArgs(bare()), [
        'curl',
        '-X',
        'GET',
        'https://api.example.com/users',
        '-L',
        '-k',
      ]);
    });

    test('uses the request method', () {
      for (final method in [
        RequestMethod.GET,
        RequestMethod.POST,
        RequestMethod.PATCH,
        RequestMethod.PUT,
        RequestMethod.DELETE,
      ]) {
        expect(curlArgs(bare(method: method))[2], method.name);
      }
    });

    test('rejects WebSocket requests', () {
      expect(() => curlFor(bare(method: RequestMethod.WS)), throwsException);
    });

    test('appends URL-encoded query parameters', () {
      final args = curlArgs(bare(
        url: 'https://api.example.com/search',
        queryParameters: {'q': 'a b&c', 'page': 2},
      ));

      expect(args[3], 'https://api.example.com/search?q=a+b%26c&page=2');
      expect(
        curlArgs(bare(queryParameters: <String, dynamic>{}))[3],
        'https://api.example.com/users',
      );
    });

    test('adds every header except content-length', () {
      final args = curlArgs(bare(headers: {
        'accept': 'application/json',
        'content-length': '42',
        'x-request-id': 'abc',
      }));

      expect(
        args,
        containsAllInOrder([
          '-H',
          'accept: application/json',
          '-H',
          'x-request-id: abc',
        ]),
      );
      expect(args.join(' '), isNot(contains('content-length')));
    });

    test('sends Map and List bodies as JSON', () {
      expect(
        curlArgs(bare(
          method: RequestMethod.POST,
          headers: {'content-type': 'application/json'},
          body: {
            'name': 'John',
            'tags': ['a'],
          },
        )),
        containsAllInOrder(['-d', '{"name":"John","tags":["a"]}', '-L']),
      );
      expect(
        curlArgs(bare(method: RequestMethod.POST, body: [1, 2])),
        containsAllInOrder(['-d', '[1,2]']),
      );
    });

    test('keeps the JSON types of body values (uses the raw body)', () {
      expect(
        curlArgs(bare(
          method: RequestMethod.POST,
          headers: {'content-type': 'application/json'},
          body: {
            'active': true,
            'n': 1,
            'd': 1.5,
            'x': null,
            'nested': {'off': false},
          },
        )),
        containsAllInOrder([
          '-d',
          '{"active":true,"n":1,"d":1.5,"x":null,"nested":{"off":false}}',
        ]),
      );
    });

    test('encodes x-www-form-urlencoded bodies', () {
      for (final header in ['content-type', 'Content-Type']) {
        final args = curlArgs(bare(
          method: RequestMethod.POST,
          headers: {header: 'application/x-www-form-urlencoded'},
          body: {'name': 'John Doe', 'age': 30},
        ));

        expect(args, containsAllInOrder(['-d', 'name=John+Doe&age=30']));
      }
    });

    test('uses -F for multipart form data', () {
      final formData = FormData.fromMap({'field': 'value'})
        ..files.add(MapEntry(
          'avatar',
          MultipartFile.fromString('bytes', filename: 'me.png'),
        ))
        ..files.add(MapEntry('blob', MultipartFile.fromString('bytes')));

      final args = curlArgs(bare(
        method: RequestMethod.POST,
        headers: {'content-type': 'multipart/form-data; boundary=x'},
        body: formData,
      ));

      expect(
        args,
        containsAllInOrder([
          '-F',
          'field=value',
          '-F',
          'avatar=@me.png',
          '-F',
          'blob=@file',
        ]),
      );
    });

    test('skips a multipart body that is not FormData', () {
      final args = curlArgs(bare(
        method: RequestMethod.POST,
        headers: {'content-type': 'multipart/form-data'},
        body: {'not': 'form data'},
      ));

      expect(args, isNot(contains('-d')));
      expect(args, isNot(contains('-F')));
    });

    test(
      'quotes a JSON body that contains a single quote',
      () {
        final args = curlArgs(bare(
          method: RequestMethod.POST,
          headers: {'content-type': 'application/json'},
          body: {'msg': "it's"},
        ));

        expect(args, containsAllInOrder(['-d', '{"msg":"it\'s"}']));
      },
      skip: "Known bug: the -d '...' argument is not shell-escaped, so a "
          "body containing ' produces a broken command.",
    );

    test(
      r'quotes header values that contain " or $',
      () {
        final args = curlArgs(bare(headers: {
          'x-quote': 'say "hi"',
          'x-price': r'$5',
        }));

        expect(
          args,
          containsAllInOrder([
            '-H',
            'x-quote: say "hi"',
            '-H',
            r'x-price: $5',
          ]),
        );
      },
      skip: r'Known bug: -H "..." values (and the URL) are not escaped, so " '
          r'breaks the command and $ is expanded by the shell.',
    );

    test(
      'sends a String body as-is',
      () {
        expect(
          curlArgs(bare(
            method: RequestMethod.POST,
            headers: {'content-type': 'text/plain'},
            body: 'plain text',
          )),
          containsAllInOrder(['-d', 'plain text']),
        );
        expect(
          curlArgs(bare(
            method: RequestMethod.POST,
            headers: {'content-type': 'application/json'},
            body: '{"a":1}',
          )),
          containsAllInOrder(['-d', '{"a":1}']),
        );
      },
      skip: 'Known bug: String bodies go through jsonEncode, so curl sends '
          r'"plain text" / "{\"a\":1}" (with the quotes) instead of the body.',
    );
  });
}
