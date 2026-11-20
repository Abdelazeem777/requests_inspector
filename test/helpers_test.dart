import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:requests_inspector/requests_inspector.dart';
import 'package:requests_inspector/src/helpers/inspector_helper.dart';
import 'package:requests_inspector/src/helpers/search_helper.dart';

void main() {
  group('SearchHelper.findMatches', () {
    test('returns nothing for an empty query or text', () {
      expect(SearchHelper.findMatches(text: 'abc', query: ''), isEmpty);
      expect(SearchHelper.findMatches(text: '', query: 'a'), isEmpty);
    });

    test('finds every case-insensitive occurrence', () {
      final matches =
          SearchHelper.findMatches(text: 'Token: TOKEN token', query: 'token');

      expect(
        matches.map((m) => [m.start, m.end]),
        [
          [0, 5],
          [7, 12],
          [13, 18],
        ],
      );
      expect(matches.first.length, 5);
      expect(matches.first.toString(), 'SearchMatch(start: 0, end: 5)');
    });

    test('returns nothing when the query is absent', () {
      expect(SearchHelper.findMatches(text: 'abc', query: 'x'), isEmpty);
    });

    test('does not return overlapping matches', () {
      // Overlapping ranges make HighlightedText render "aa" + "aa".
      final matches = SearchHelper.findMatches(text: 'aaa', query: 'aa');

      expect(matches.map((m) => [m.start, m.end]), [
        [0, 2],
      ]);
    });
  });

  group('SearchHelper and InspectorController', () {
    late InspectorController controller;

    setUp(() {
      controller = InspectorController(
        enabled: true,
        showInspectorOn: ShowInspectorOn.LongPress,
      );
    });

    tearDown(() => controller.dispose());

    int helperCount(String text, String query) =>
        SearchHelper.findMatches(text: text, query: query).length;

    RequestDetails urlOnly(String url) => RequestDetails(
          requestMethod: RequestMethod.GET,
          url: url,
          sentTime: DateTime(2024),
        );

    test('agree when matches do not overlap', () {
      controller
        ..selectedRequest = urlOnly('https://api.example.com/users/users')
        ..updateSearchQuery('users');

      expect(controller.totalMatches, 2);
      expect(
        controller.totalMatches,
        helperCount('URL: https://api.example.com/users/users', 'users'),
      );
    });

    test('agree when matches overlap ("aa" in "aaa")', () {
      controller
        ..selectedRequest = urlOnly('https://api.example.com/aaa')
        ..updateSearchQuery('aa');

      expect(
        controller.totalMatches,
        helperCount('URL: https://api.example.com/aaa', 'aa'),
      );
    });
  });

  group('InspectorHelper', () {
    test('extractTimeText formats HH:MM.SS', () {
      expect(
        InspectorHelper.extractTimeText(DateTime(2024, 1, 2, 13, 5, 9)),
        '13:05.09',
      );
    });

    test('calculateDuration picks the largest sensible unit', () {
      final start = DateTime(2024);
      String after(Duration d) =>
          InspectorHelper.calculateDuration(start, start.add(d));

      expect(after(const Duration(milliseconds: 999)), '999 ms');
      expect(after(const Duration(milliseconds: 1500)), '1 s');
      expect(after(const Duration(seconds: 61)), '1 m');
      expect(after(const Duration(minutes: 125)), '2 h');
      expect(after(const Duration(days: 3)), '3 d');
    });

    test('specifyStatusCodeColor maps status classes to colors', () {
      expect(InspectorHelper.specifyStatusCodeColor(null), Colors.red[400]);
      expect(InspectorHelper.specifyStatusCodeColor(500), Colors.red[400]);
      expect(InspectorHelper.specifyStatusCodeColor(404), Colors.red[400]);
      expect(InspectorHelper.specifyStatusCodeColor(301), Colors.yellow[400]);
      expect(InspectorHelper.specifyStatusCodeColor(200), Colors.green[400]);
    });
  });
}
