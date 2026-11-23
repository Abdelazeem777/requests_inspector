import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:requests_inspector/src/version.dart';

void main() {
  test('packageVersion matches the version in pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(
      r'^version:\s*(\S+)',
      multiLine: true,
    ).firstMatch(pubspec)!.group(1);

    expect(packageVersion, version);
  });
}
