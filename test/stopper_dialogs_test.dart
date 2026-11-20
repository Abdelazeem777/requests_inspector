import 'dart:convert';

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

/// The text currently shown in [field].
String textOf(WidgetTester tester, Finder field) =>
    tester.widget<TextField>(field).controller!.text;

/// Edits [field] and then restores its text, like a user who types and
/// deletes a character. `onChanged` fires with the original text, so the
/// dialog decodes it into new data. (Entering the same text alone doesn't
/// call `onChanged`.)
Future<void> retypeSameText(WidgetTester tester, Finder field) async {
  final text = textOf(tester, field);
  await tester.enterText(field, '$text ');
  await tester.enterText(field, text);
}

/// `==` treats `1 == 1.0`; the JSON encoding also tells `true` from `"true"`,
/// `1` from `"1"` and `null` from `""`.
void expectSameJson(dynamic actual, dynamic expected) {
  expect(actual, expected);
  expect(jsonEncode(actual), jsonEncode(expected));
}

/// A body with every JSON type, at the first level and nested.
const typedBody = <String, dynamic>{
  'name': 'John',
  'active': true,
  'deleted': false,
  'age': 30,
  'score': 1.5,
  'nickname': null,
  'tags': ['a', 1, 2.5, true, null],
  'address': {'zip': 12345, 'verified': true, 'note': null},
};

/// The response body field of [ResponseStopperEditorDialog].
Finder responseBodyField() => find
    .descendant(of: find.byType(ListView), matching: find.byType(TextField))
    .at(1);

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

    testWidgets('keeps every JSON type when a field is edited back as is',
        (tester) async {
      final typed = sampleRequest(
        requestMethod: RequestMethod.POST,
        headers: {'x-retry': 3, 'x-debug': true},
        queryParameters: {'page': 1, 'all': true},
        requestBody: typedBody,
      );
      final result = await showTestDialog<RequestDetails>(
        tester,
        RequestStopperEditorDialog(requestDetails: typed),
      );

      for (final label in [
        'Headers: ',
        'Query Parameters: ',
        'Request Body: '
      ]) {
        await retypeSameText(tester, fieldAfter(label));
      }
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      final sent = result()!;
      expect(sent, isNot(same(typed)), reason: 'the fields were decoded');
      expectSameJson(sent.headers, typed.headers);
      expectSameJson(sent.queryParameters, typed.queryParameters);
      expectSameJson(sent.requestBody, typedBody);
    });

    testWidgets('editing one body value keeps the types of the others',
        (tester) async {
      final result = await showTestDialog<RequestDetails>(
        tester,
        RequestStopperEditorDialog(
          requestDetails: sampleRequest(
            requestMethod: RequestMethod.POST,
            requestBody: typedBody,
          ),
        ),
      );

      final body = fieldAfter('Request Body: ');
      final text = textOf(tester, body);
      expect(text, contains('"active": true'));
      expect(text, contains('"age": 30'));
      expect(text, contains('"nickname": null'));
      await tester.enterText(
          body, text.replaceFirst('"name": "John"', '"name": "Jo"'));
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expectSameJson(result()!.requestBody, {...typedBody, 'name': 'Jo'});
    });

    for (final edit in <List<Object>>[
      [true, 'true', 'false', false],
      [42, '42', '43', 43],
      [1.5, '1.5', '2', 2.0],
      ['hello', '"hello"', '"hello world"', 'hello world'],
    ]) {
      final body = edit[0];
      testWidgets('edits a top-level ${body.runtimeType} body', (tester) async {
        final result = await showTestDialog<RequestDetails>(
          tester,
          RequestStopperEditorDialog(
            requestDetails: sampleRequest(
              requestMethod: RequestMethod.POST,
              requestBody: body,
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(textOf(tester, fieldAfter('Request Body: ')), edit[1]);
        await tester.enterText(fieldAfter('Request Body: '), '${edit[2]}');
        await tester.tap(find.text('Send'));
        await tester.pumpAndSettle();

        expectSameJson(result()!.requestBody, edit[3]);
        expect(result()!.requestBody.runtimeType, edit[3].runtimeType);
      });
    }
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

    testWidgets('keeps every JSON type when the body is edited back as is',
        (tester) async {
      final result = await showTestDialog<ResponseDetails>(
        tester,
        const ResponseStopperEditorDialog(
          responseDetails: ResponseDetails(
            statusCode: 200,
            url: 'https://api.example.com/users',
            responseBody: typedBody,
          ),
        ),
      );

      await retypeSameText(tester, responseBodyField());
      await tester.tap(find.text('Receive'));
      await tester.pumpAndSettle();

      expectSameJson(result()!.responseBody, typedBody);
    });

    for (final edit in <List<Object>>[
      [true, 'true', 'false', false],
      [42, '42', '7', 7],
      [1.5, '1.5', '0.5', 0.5],
      ['hello', '"hello"', '"bye"', 'bye'],
    ]) {
      final body = edit[0];
      testWidgets('edits a top-level ${body.runtimeType} body', (tester) async {
        final result = await showTestDialog<ResponseDetails>(
          tester,
          ResponseStopperEditorDialog(
            responseDetails: ResponseDetails(
              statusCode: 200,
              url: 'https://api.example.com/users',
              responseBody: body,
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(textOf(tester, responseBodyField()), edit[1]);
        await tester.enterText(responseBodyField(), '${edit[2]}');
        await tester.tap(find.text('Receive'));
        await tester.pumpAndSettle();

        expectSameJson(result()!.responseBody, edit[3]);
        expect(result()!.responseBody.runtimeType, edit[3].runtimeType);
      });
    }
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

    testWidgets('a request body left as is is sent with its JSON types',
        (tester) async {
      await pumpInspectorApp(tester, navigatorKey: navigatorKey);
      InspectorController().requestStopperEnabled = true;

      final future = dio.post('/users', data: typedBody);
      await tester.pumpAndSettle();
      await retypeSameText(tester, fieldAfter('Request Body: '));
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      await future;

      expectSameJson(adapter.requests.single.data, typedBody);
      expectSameJson(
          InspectorController().requestsList.single.requestBody, typedBody);
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

    testWidgets('a response body left as is reaches the app with its types',
        (tester) async {
      adapter = FakeHttpClientAdapter.json(typedBody);
      dio = inspectedDio(adapter);
      await pumpInspectorApp(tester, navigatorKey: navigatorKey);
      InspectorController().responseStopperEnabled = true;

      final future = dio.get('/users');
      await tester.pumpAndSettle();
      await retypeSameText(tester, responseBodyField());
      await tester.tap(find.text('Receive'));
      await tester.pumpAndSettle();

      expectSameJson((await future).data, typedBody);
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
