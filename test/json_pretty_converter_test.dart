import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:requests_inspector/src/json_pretty_converter.dart';

void main() {
  final converter = JsonPrettyConverter();
  const encoder = JsonEncoder.withIndent('  ');

  test('JsonPrettyConverter is a singleton', () {
    expect(JsonPrettyConverter(), same(converter));
  });

  group('convert', () {
    test('pretty prints a top-level Map', () {
      final input = {
        'id': 1,
        'name': 'John',
        'tags': ['a', 'b'],
        'address': {'city': 'Cairo'},
      };

      expect(converter.convert(input), encoder.convert(input));
    });

    test('pretty prints a top-level List', () {
      final input = [
        {'id': 1},
        'two',
        3,
      ];

      expect(converter.convert(input), encoder.convert(input));
    });

    test('JSON-encodes a top-level String', () {
      expect(converter.convert('hello'), '"hello"');
    });

    test('renders null as an empty string', () {
      expect(converter.convert(null), '');
    });

    test(
      'returns a String for a top-level bool',
      () {
        expect(converter.convert(true), 'true');
        expect(converter.convert(false), 'false');
      },
      skip: "Known bug: returns the bool itself, so callers that expect a "
          "String crash with \"type 'bool' is not a subtype of type "
          "'String'\". See PR #64.",
    );

    test(
      'returns a String for a top-level int',
      () => expect(converter.convert(42), '42'),
      skip: 'Known bug: returns the int itself instead of a String. '
          'See PR #64.',
    );

    test(
      'returns a String for a top-level double',
      () => expect(converter.convert(1.5), '1.5'),
      skip: 'Known bug: returns the double itself instead of a String. '
          'See PR #64.',
    );

    test('keeps nested bool, int, double and String values as JSON literals',
        () {
      // Guards against fixing the top-level case by stringifying primitives
      // everywhere (which would render `"flag": "true"`).
      final input = {
        'flag': true,
        'count': 3,
        'ratio': 1.5,
        'name': 'John',
        'list': [1, true, 2.5, 'x'],
        'nested': {'off': false, 'n': 0},
      };

      expect(converter.convert(input), encoder.convert(input));
    });

    test(
      'keeps nested null values as null',
      () {
        final input = {'name': null, 'id': 1};

        expect(converter.convert(input), encoder.convert(input));
      },
      skip: 'Known bug: first-level null values in a Map are rendered as "" '
          '(convert(null) returns an empty string), e.g. "name": "".',
    );

    test('stringifies other first-level values', () {
      final when = DateTime.utc(2024);

      expect(
        converter.convert({'when': when}),
        encoder.convert({'when': when.toString()}),
      );
    });

    test('describes FormData fields and file names', () {
      final formData = FormData.fromMap({'name': 'John'})
        ..files.add(MapEntry(
          'avatar',
          MultipartFile.fromString('bytes', filename: 'me.png'),
        ));

      expect(
        converter.convert(formData),
        'FormData:\n${encoder.convert({
              'name': 'John',
              'avatar': 'me.png',
            })}',
      );
    });

    test('falls back to toString for other objects', () {
      expect(
        converter.convert(Uri.parse('https://example.com')),
        'https://example.com',
      );
    });
  });

  group('deconvertFrom', () {
    test('returns null without a previous type', () {
      expect(converter.deconvertFrom('{}', null), isNull);
    });

    test('decodes Maps, including private implementation types', () {
      for (final type in ['Map<String, dynamic>', '_Map<String, dynamic>']) {
        expect(converter.deconvertFrom('{"a": 1}', type), {'a': 1});
      }
    });

    test('decodes Lists', () {
      expect(converter.deconvertFrom('[1, "b"]', 'List<dynamic>'), [1, 'b']);
    });

    test('returns Strings verbatim', () {
      expect(converter.deconvertFrom('plain', 'String'), 'plain');
    });

    test('returns null for invalid JSON or unsupported types', () {
      expect(
          converter.deconvertFrom('{not json', 'Map<String, dynamic>'), isNull);
      expect(converter.deconvertFrom('1', 'int'), isNull);
    });

    test('round-trips Maps and Lists', () {
      final map = {
        'a': [1, 2],
        'b': {'c': true},
      };
      final list = [
        1,
        {'x': 'y'},
      ];

      expect(
        converter.deconvertFrom(
            converter.convert(map), map.runtimeType.toString()),
        map,
      );
      expect(
        converter.deconvertFrom(
            converter.convert(list), list.runtimeType.toString()),
        list,
      );
    });

    test(
      'round-trips Strings',
      () {
        const body = 'hello';

        expect(
            converter.deconvertFrom(converter.convert(body), 'String'), body);
      },
      skip: 'Known bug: convert() JSON-encodes Strings but deconvertFrom() '
          'returns them verbatim, so editing a String body in the stopper '
          'dialogs adds literal quotes ("hello").',
    );
  });
}
