import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:requests_inspector/requests_inspector.dart';
import 'package:requests_inspector/src/json_pretty_converter.dart';

import 'helpers/fakes.dart';
import 'helpers/inspector_app.dart';
import 'helpers/plugin_mocks.dart';

/// "needle" appears 7 times: URL 1, headers 2, body 2, GraphQL vars 1,
/// response 1.
final needles = sampleRequest(
  url: 'https://api.example.com/needle',
  headers: {'x-needle': 'NEEDLE'},
  queryParameters: null,
  requestBody: {'needle': 'needle'},
  graphqlRequestVars: {'id': 'needle'},
  responseBody: {
    'items': ['Needle'],
  },
);

Future<void> showDetails(
  WidgetTester tester,
  RequestDetails request, {
  bool treeView = true,
}) async {
  await pumpInspectorApp(tester, defaultTreeViewEnabled: treeView);
  await openInspector(tester, requests: [request]);
  await tester.tap(find.text(request.requestName));
  await tester.pumpAndSettle();
}

Future<void> search(WidgetTester tester, String query) async {
  await tester.tap(find.byTooltip('Search'));
  await tester.pumpAndSettle();
  await tester.enterText(find.widgetWithText(TextField, 'Search...'), query);
  await tester.pumpAndSettle();
}

List<String> activeMatches(WidgetTester tester) => [
  for (final span in highlightedSpans(tester))
    if (span.style!.backgroundColor == Colors.orange) span.text!,
];

void main() {
  group('RequestDetailsPage', () {
    testWidgets('shows every section of the request', (tester) async {
      await showDetails(tester, needles);

      expect(find.text('GET - NEEDLE'), findsOneWidget);
      expect(find.text('Status: 200'), findsOneWidget);
      expect(
        selectableTexts(tester).first,
        'Sent at: 10:20.30\nReceived at: 10:20.30\nDuration: 250 ms\n\n'
        'URL: https://api.example.com/needle',
      );
      for (final title in [
        'Headers',
        'Request Body',
        'GraphQL Request Vars',
        'Response Body',
      ]) {
        expect(find.text(title), findsOneWidget, reason: title);
      }
      expect(find.text('Query Parameters'), findsNothing);
      expect(selectableTexts(tester), contains('"x-needle" : "NEEDLE",'));
    });

    testWidgets('labels FormData bodies', (tester) async {
      await showDetails(
        tester,
        sampleRequest(
          requestMethod: RequestMethod.POST,
          requestBody: FormData.fromMap({'name': 'John'}),
        ),
      );

      expect(find.text('Request Body (Form Data)'), findsOneWidget);
    });

    testWidgets('copies a section to the clipboard', (tester) async {
      FakeClipboard.install();
      await showDetails(tester, needles);

      final headersCopy = find.descendant(
        of: find.ancestor(
          of: find.text('Headers'),
          matching: find.byType(ExpansionTile),
        ),
        matching: find.byIcon(Icons.copy),
      );
      await tester.tap(headersCopy);
      await tester.pump();

      expect(
        FakeClipboard.text,
        JsonPrettyConverter().convert(needles.headers),
      );
      expect(find.text('Copied to clipboard'), findsOneWidget);
    });

    testWidgets('copies the URL as is, without quotes', (tester) async {
      FakeClipboard.install();
      await showDetails(tester, needles);

      await tester.tap(
        find.descendant(
          of: find.ancestor(
            of: find.text('GET - NEEDLE'),
            matching: find.byType(ExpansionTile),
          ),
          matching: find.byIcon(Icons.copy),
        ),
      );
      await tester.pump();

      expect(FakeClipboard.text, 'https://api.example.com/needle');
    });

    testWidgets('labels the copy icons for accessibility', (tester) async {
      final semantics = tester.ensureSemantics();
      await showDetails(tester, sampleRequest(graphqlRequestVars: {'id': 1}));

      for (final section in [
        'URL',
        'Headers',
        'Query Parameters',
        'GraphQL Request Vars',
        'Response Body',
      ]) {
        expect(
          tester.getSemantics(find.byTooltip('Copy $section')),
          containsSemantics(tooltip: 'Copy $section', hasTapAction: true),
          reason: section,
        );
      }

      InspectorController().selectedRequest = sampleRequest(
        requestMethod: RequestMethod.POST,
        requestBody: FormData.fromMap({'name': 'John'}),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Copy Request Body'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('renders bodies as text when the tree view is off', (
      tester,
    ) async {
      await showDetails(tester, needles, treeView: false);

      expect(selectableTexts(tester), contains('  "x-needle": "NEEDLE"'));
      expect(selectableTexts(tester), contains('  "needle": "needle"'));
    });

    testWidgets('re-runs the request from the Run button', (tester) async {
      await showDetails(
        tester,
        sampleRequest(url: 'https://api.example.com/x'),
      );

      await tester.tap(find.text('Run'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // flutter_test answers every HttpClient request with HTTP 400.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(InspectorController().selectedRequest!.statusCode, 400);
      expect(find.text('Status: 400'), findsOneWidget);
    });
  });

  group('RequestDetailsPage search', () {
    testWidgets('highlights every match and shows the count', (tester) async {
      await showDetails(tester, needles);

      await search(tester, 'NEEDLE');

      expect(InspectorController().totalMatches, 7);
      expect(find.text('1 / 7'), findsOneWidget);
      expect(highlightedSpans(tester), hasLength(7));
      expect(
        highlightedSpans(tester).map((span) => span.text!.toLowerCase()),
        everyElement('needle'),
      );
      expect(activeMatches(tester), hasLength(1));
    });

    testWidgets('moves the active match with next and previous', (
      tester,
    ) async {
      await showDetails(tester, needles);
      await search(tester, 'needle');

      await tester.tap(find.byTooltip('Next match'));
      await tester.pumpAndSettle();
      expect(find.text('2 / 7'), findsOneWidget);
      expect(InspectorController().currentMatchIndex, 1);
      expect(activeMatches(tester), ['needle'], reason: 'in "x-needle"');

      await tester.tap(find.byTooltip('Previous match'));
      await tester.tap(find.byTooltip('Previous match'));
      await tester.pumpAndSettle();
      expect(find.text('7 / 7'), findsOneWidget);
      expect(activeMatches(tester), ['Needle'], reason: 'the response item');

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('1 / 7'), findsOneWidget, reason: 'enter = next');
    });

    testWidgets('highlights matches in the text view', (tester) async {
      await showDetails(tester, needles, treeView: false);

      await search(tester, 'needle');

      expect(find.text('1 / 7'), findsOneWidget);
      expect(highlightedSpans(tester), hasLength(7));
    });

    testWidgets('shows no counter without matches', (tester) async {
      await showDetails(tester, needles);

      await search(tester, 'haystack');

      expect(InspectorController().totalMatches, 0);
      expect(find.textContaining(' / '), findsNothing);
      expect(highlightedSpans(tester), isEmpty);
    });

    testWidgets('closing the search bar clears query and highlights', (
      tester,
    ) async {
      await showDetails(tester, needles);
      await search(tester, 'needle');

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Search...'), findsNothing);
      expect(InspectorController().searchQuery, isEmpty);
      expect(highlightedSpans(tester), isEmpty);

      await tester.tap(find.byTooltip('Search'));
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Search...'),
      );
      expect(field.controller!.text, isEmpty);
    });

    testWidgets('keeps the text intact for overlapping matches', (
      tester,
    ) async {
      await showDetails(
        tester,
        RequestDetails(
          requestMethod: RequestMethod.GET,
          url: 'https://api.example.com/aaa',
          sentTime: DateTime(2024),
        ),
      );

      await search(tester, 'aa');

      expect(
        selectableTexts(tester).first,
        'Sent at: 00:00.00\n\nURL: https://api.example.com/aaa',
      );
      expect(highlightedSpans(tester), hasLength(1));
      expect(find.text('1 / 1'), findsOneWidget);
    });
  });

  // Used to throw "type 'bool' is not a subtype of type 'String'" because
  // JsonPrettyConverter.convert returned top-level bools/numbers as-is (#64).
  group('top-level primitive bodies', () {
    for (final body in <Object>[true, 42, 1.5]) {
      for (final treeView in [true, false]) {
        testWidgets('shows a top-level ${body.runtimeType} response '
            '(tree view: $treeView)', (tester) async {
          await showDetails(
            tester,
            sampleRequest(responseBody: body),
            treeView: treeView,
          );

          expect(tester.takeException(), isNull);
          expect(find.text('Response Body'), findsOneWidget);
          expect(selectableTexts(tester), contains('$body'));
        });
      }
    }

    testWidgets('shows a top-level bool request body', (tester) async {
      await showDetails(
        tester,
        sampleRequest(requestMethod: RequestMethod.POST, requestBody: false),
        treeView: false,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Request Body'), findsOneWidget);
      expect(selectableTexts(tester), contains('false'));
    });
  });

  testWidgets('shows nested bool, number and null values as JSON literals', (
    tester,
  ) async {
    await showDetails(
      tester,
      sampleRequest(responseBody: {'active': true, 'age': 30, 'nick': null}),
      treeView: false,
    );

    final text = selectableTexts(tester).join('\n');
    expect(text, contains('"active": true'));
    expect(text, contains('"age": 30'));
    expect(text, contains('"nick": null'));
  });
}
