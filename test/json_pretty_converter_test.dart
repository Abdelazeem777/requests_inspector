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

    test('returns a String for a top-level bool', () {
      expect(converter.convert(true), 'true');
      expect(converter.convert(false), 'false');
    });

    test('returns a String for a top-level int', () {
      expect(converter.convert(42), '42');
    });

    test('returns a String for a top-level double', () {
      expect(converter.convert(1.5), '1.5');
    });

    test(
      'keeps nested bool, int, double and String values as JSON literals',
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
      },
    );

    test('keeps nested null values as null', () {
      final input = {
        'name': null,
        'id': 1,
        'list': [null],
        'nested': {'x': null},
      };

      expect(converter.convert(input), encoder.convert(input));
    });

    test('stringifies other first-level values', () {
      final when = DateTime.utc(2024);

      expect(
        converter.convert({'when': when}),
        encoder.convert({'when': when.toString()}),
      );
    });

    test('stringifies non-JSON values at any depth', () {
      final when = DateTime.utc(2024);

      expect(
        converter.convert({
          'events': [
            {'when': when, 'ok': true},
          ],
        }),
        encoder.convert({
          'events': [
            {'when': when.toString(), 'ok': true},
          ],
        }),
      );
    });

    test('stringifies non-String Map keys', () {
      expect(
        converter.convert({
          1: 'a',
          'nested': {2: true},
        }),
        encoder.convert({
          '1': 'a',
          'nested': {'2': true},
        }),
      );
    });

    test('describes FormData fields and file names', () {
      final formData = FormData.fromMap({'name': 'John'})
        ..files.add(
          MapEntry(
            'avatar',
            MultipartFile.fromString('bytes', filename: 'me.png'),
          ),
        );

      expect(
        converter.convert(formData),
        'FormData:\n${encoder.convert({'name': 'John', 'avatar': 'me.png'})}',
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
      expect(converter.deconvertFrom('"unclosed', 'String'), '"unclosed');
      expect(converter.deconvertFrom('42', 'String'), '42');
    });

    test('decodes JSON string literals into Strings', () {
      expect(converter.deconvertFrom('"hello world"', 'String'), 'hello world');
      expect(converter.deconvertFrom(r'"{\"a\":1}"', 'String'), '{"a":1}');
    });

    test('decodes bools', () {
      expect(converter.deconvertFrom('false', 'bool'), isFalse);
      expect(converter.deconvertFrom(' true\n', 'bool'), isTrue);
    });

    test('decodes ints and doubles, keeping a double a double', () {
      expect(converter.deconvertFrom('43', 'int'), 43);
      expect(converter.deconvertFrom('-1.25', 'double'), -1.25);
      expect(converter.deconvertFrom('3', 'double'), isA<double>());
    });

    test('returns null for invalid input or unsupported types', () {
      expect(
        converter.deconvertFrom('{not json', 'Map<String, dynamic>'),
        isNull,
      );
      expect(converter.deconvertFrom('yes', 'bool'), isNull);
      expect(converter.deconvertFrom('abc', 'int'), isNull);
      expect(converter.deconvertFrom('2024-01-01', 'DateTime'), isNull);
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
          converter.convert(map),
          map.runtimeType.toString(),
        ),
        map,
      );
      expect(
        converter.deconvertFrom(
          converter.convert(list),
          list.runtimeType.toString(),
        ),
        list,
      );
    });

    test('round-trips Strings', () {
      const body = 'hello';

      expect(converter.deconvertFrom(converter.convert(body), 'String'), body);
    });
  });

  group('convert -> deconvertFrom round trip', () {
    /// Decodes what [convert] shows for [value] as the stopper editors do.
    dynamic roundTrip(Object? value) => converter.deconvertFrom(
      converter.convert(value),
      value.runtimeType.toString(),
    );

    /// `==` treats `1 == 1.0`, so also compare the JSON encodings, which tell
    /// `true` from `"true"`, `1` from `1.0` and `null` from `""`.
    void expectLossless(Object? value) {
      final back = roundTrip(value);
      final reason = 'value: ${jsonEncode(value)}';

      expect(back, value, reason: reason);
      expect(jsonEncode(back), jsonEncode(value), reason: reason);
      if (value is Map) {
        expect(back, isA<Map>(), reason: reason);
      } else if (value is List) {
        expect(back, isA<List>(), reason: reason);
      } else {
        expect(back.runtimeType, value.runtimeType, reason: reason);
      }
    }

    const everyJsonType = <String, dynamic>{
      'string': 'John',
      'emptyString': '',
      'stringThatLooksLikeJson': '{"a": 1}',
      'stringThatLooksLikeABool': 'true',
      'stringThatLooksLikeANumber': '1',
      'escapes': 'quote " backslash \\ newline \n',
      'true': true,
      'false': false,
      'int': 42,
      'zero': 0,
      'negative': -7,
      'double': 1.5,
      'wholeDouble': 2.0,
      'null': null,
      'emptyList': [],
      'emptyMap': {},
    };

    test('top-level bool, int, double, String and null', () {
      for (final value in <Object?>[
        true,
        false,
        0,
        42,
        -7,
        1.5,
        2.0,
        -0.25,
        '',
        'hello',
        'say "hi"\nbye',
        '{"a": 1}',
        'true',
        null,
      ]) {
        expectLossless(value);
      }
    });

    test('a top-level Map with every JSON type, nested at every depth', () {
      expectLossless(<String, dynamic>{
        ...everyJsonType,
        'list': everyJsonType.values.toList(),
        'map': everyJsonType,
        'deep': {
          'list': [
            everyJsonType,
            [everyJsonType.values.toList()],
          ],
        },
      });
    });

    test('a top-level List with every JSON type, nested at every depth', () {
      expectLossless(<dynamic>[
        ...everyJsonType.values,
        everyJsonType,
        [
          ...everyJsonType.values,
          {'map': everyJsonType},
        ],
      ]);
    });

    test('a Map with only primitive first-level values', () {
      // Regression guard (PR #64): first-level values must not come back as
      // Strings, e.g. {"a": "true", "n": "1"}.
      expectLossless({'a': true, 'n': 1, 'd': 1.5, 'x': null, 's': 'str'});
    });
  });
}
