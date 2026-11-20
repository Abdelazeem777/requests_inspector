import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:requests_inspector/requests_inspector.dart';
import 'package:requests_inspector/src/request_stopper_editor_dialog.dart';
import 'package:requests_inspector/src/response_stopper_editor_dialog.dart';

import 'helpers/fakes.dart';
import 'helpers/inspector_app.dart';

/// Shows [dialog] and returns a getter for the value it was closed with.
Future<T? Function()> showTestDialog<T>(
  WidgetTester tester,
  Widget dialog,
) async {
  T? result;
  tester.view
    ..physicalSize = const Size(800, 1600)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => TextButton(
        onPressed: () async => result =
            await showDialog<T>(context: context, builder: (_) => dialog),
        child: const Text('open'),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return () => result;
}

/// The dialog text field that follows the [label] text.
Finder fieldAfter(String label) => find
    .descendant(
      of: find.byType(ListView),
      matching: find.byType(TextField),
    )
    .at(const {
      'URL: ': 0,
      'Headers: ': 1,
      'Query Parameters: ': 2,
      'Request Body: ': 3,
    }[label]!);

void main() {
  group('RequestStopperEditorDialog', () {
    final request = sampleRequest(
      requestMethod: RequestMethod.POST,
      headers: {'a': 'b'},
      queryParameters: {'page': 1},
      requestBody: {'name': 'John'},
    );

    testWidgets('returns the request unchanged when sent as is',
        (tester) async {
      final result = await showTestDialog<RequestDetails>(
        tester,
        RequestStopperEditorDialog(requestDetails: request),
      );

      expect(find.text('https://api.example.com/users'), findsOneWidget);
      expect(find.text('POST'), findsOneWidget);
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(result(), same(request));
    });

    testWidgets('returns the edited method, URL, headers, query and body',
        (tester) async {
      final result = await showTestDialog<RequestDetails>(
        tester,
        RequestStopperEditorDialog(requestDetails: request),
      );

      await tester.tap(find.text('POST'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PATCH').last);
      await tester.pumpAndSettle();
      await tester.enterText(fieldAfter('URL: '), 'https://x.io/edited');
      await tester.enterText(fieldAfter('Headers: '), '{"a": "c"}');
      await tester.enterText(fieldAfter('Query Parameters: '), '{"page": 2}');
      await tester.enterText(fieldAfter('Request Body: '), '{"name": "Jo"}');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      final edited = result()!;
      expect(edited.requestMethod, RequestMethod.PATCH);
      expect(edited.url, 'https://x.io/edited');
      expect(edited.headers, {'a': 'c'});
      expect(edited.queryParameters, {'page': 2});
      expect(edited.requestBody, {'name': 'Jo'});
    });
  });

  group('ResponseStopperEditorDialog', () {
    const response = ResponseDetails(
      statusCode: 200,
      url: 'https://api.example.com/users',
      headers: {'content-type': 'application/json'},
      responseBody: {'id': 1},
    );

    testWidgets('returns an equal response when received as is',
        (tester) async {
      final result = await showTestDialog<ResponseDetails>(
        tester,
        const ResponseStopperEditorDialog(responseDetails: response),
      );

      final statusField = tester.widget<TextField>(find
          .descendant(
              of: find.byType(ListView), matching: find.byType(TextField))
          .first);
      expect(statusField.controller!.text, '200');
      await tester.tap(find.text('Receive'));
      await tester.pumpAndSettle();

      expect(result()!.toMap(), response.toMap());
    });

    testWidgets('returns the edited status, body and headers', (tester) async {
      final result = await showTestDialog<ResponseDetails>(
        tester,
        const ResponseStopperEditorDialog(responseDetails: response),
      );
      final fields = find.descendant(
        of: find.byType(ListView),
        matching: find.byType(TextField),
      );

      await tester.enterText(fields.at(0), '4x04');
      await tester.enterText(fields.at(1), '{"id": 2}');
      await tester.enterText(fields.at(2), '{"x-edited": "yes"}');
      await tester.tap(find.text('Receive'));
      await tester.pumpAndSettle();

      final edited = result()!;
      expect(edited.statusCode, 404, reason: 'digits only, max 3');
      expect(edited.responseBody, {'id': 2});
      expect(edited.headers, {'x-edited': 'yes'});
    });

    testWidgets('falls back to 200 for an empty status code', (tester) async {
      final result = await showTestDialog<ResponseDetails>(
        tester,
        const ResponseStopperEditorDialog(responseDetails: response),
      );

      await tester.enterText(
        find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(TextField),
            )
            .first,
        '',
      );
      await tester.tap(find.text('Receive'));
      await tester.pumpAndSettle();

      expect(result()!.statusCode, 200);
    });
  });

  group('Stoppers end to end', () {
    late GlobalKey<NavigatorState> navigatorKey;
    late FakeHttpClientAdapter adapter;
    late Dio dio;

    setUp(() {
      navigatorKey = GlobalKey<NavigatorState>();
      adapter = FakeHttpClientAdapter.json({'id': 1});
      dio = inspectedDio(adapter);
    });

    testWidgets('the request stopper lets the user edit before sending',
        (tester) async {
      await pumpInspectorApp(tester, navigatorKey: navigatorKey);
      InspectorController().requestStopperEnabled = true;

      final future = dio.get('/users');
      await tester.pumpAndSettle();
      expect(find.text('Send'), findsOneWidget);

      await tester.enterText(fieldAfter('URL: '), 'https://x.io/edited');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      await future;

      expect(adapter.requests.single.uri.toString(), 'https://x.io/edited');
      expect(
          InspectorController().requestsList.single.url, 'https://x.io/edited');
    });

    testWidgets('requests outside the stopper filters are not stopped',
        (tester) async {
      await pumpInspectorApp(tester, navigatorKey: navigatorKey);
      InspectorController()
        ..requestStopperEnabled = true
        ..setRequestStopperFilterMethod(RequestMethod.POST);

      final future = dio.get('/users');
      await tester.pumpAndSettle();

      expect(find.text('Send'), findsNothing);
      await future;
      expect(adapter.requests, hasLength(1));
    });

    testWidgets('stoppers are skipped without a navigatorKey', (tester) async {
      await pumpInspectorApp(tester);
      InspectorController()
        ..requestStopperEnabled = true
        ..responseStopperEnabled = true;

      final future = dio.get('/users');
      await tester.pumpAndSettle();

      expect(find.text('Send'), findsNothing);
      expect(find.text('Receive'), findsNothing);
      expect((await future).data, {'id': 1});
    });

    testWidgets('the response stopper lets the user edit what the app gets',
        (tester) async {
      await pumpInspectorApp(tester, navigatorKey: navigatorKey);
      InspectorController().responseStopperEnabled = true;

      final future = dio.get('/users');
      await tester.pumpAndSettle();
      expect(find.text('Receive'), findsOneWidget);

      await tester.enterText(
        find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(TextField),
            )
            .at(1),
        '{"id": 99}',
      );
      await tester.tap(find.text('Receive'));
      await tester.pumpAndSettle();

      expect((await future).data, {'id': 99});
      expect(
          InspectorController().requestsList.single.responseBody, {'id': 99});
    });

    testWidgets('responses outside the stopper filters are not stopped',
        (tester) async {
      await pumpInspectorApp(tester, navigatorKey: navigatorKey);
      InspectorController()
        ..responseStopperEnabled = true
        ..setResponseStopperFilterStatusCode(500);

      final future = dio.get('/users');
      await tester.pumpAndSettle();

      expect(find.text('Receive'), findsNothing);
      expect((await future).data, {'id': 1});
    });
  });
}
