import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:requests_inspector/requests_inspector.dart';
import 'package:requests_inspector/src/json_tree_view_widget.dart';
import 'package:requests_inspector/src/shared_widgets/request_item.dart';

import 'helpers/fakes.dart';
import 'helpers/inspector_app.dart';
import 'helpers/plugin_mocks.dart';

final users = sampleRequest(
  url: 'https://api.example.com/users',
  statusCode: 200,
  queryParameters: {'page': 1},
  responseBody: {'id': 1, 'name': 'John'},
);
final createOrder = sampleRequest(
  requestMethod: RequestMethod.POST,
  url: 'https://api.example.com/orders',
  statusCode: 500,
  requestBody: {'item': 'book'},
  responseBody: 'Internal error',
);
final failed = RequestDetails(
  requestMethod: RequestMethod.DELETE,
  url: 'https://api.example.com/sessions',
  sentTime: DateTime(2024, 1, 2, 10, 20, 30),
);

Future<void> openMenu(WidgetTester tester) async {
  // The test font draws every glyph 1em wide, which makes the fixed-width
  // menu rows ("Responses Stopper" + switch) overflow; shrink the text.
  tester.platformDispatcher.textScaleFactorTestValue = 0.7;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.tap(find.byIcon(Icons.more_vert));
  await tester.pumpAndSettle();
}

Future<void> closeMenu(WidgetTester tester) async {
  await tester.tapAt(const Offset(10, 700));
  await tester.pumpAndSettle();
}

Brightness inspectorBrightness(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(Scaffold).last)).brightness;

void main() {
  group('Inspector requests list', () {
    testWidgets('shows an empty state', (tester) async {
      await pumpInspectorApp(tester);
      await openInspector(tester);

      expect(find.text('No requests added yet'), findsOneWidget);
      expect(find.text('Clear All'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget, reason: 'URL search');
    });

    testWidgets('lists requests newest first with their summary',
        (tester) async {
      await pumpInspectorApp(tester);
      await openInspector(tester, requests: [users, createOrder, failed]);

      final items = tester
          .widgetList<ListTile>(find.descendant(
            of: find.byType(RequestItemWidget),
            matching: find.byType(ListTile),
          ))
          .toList();
      expect(
        items.map((tile) => (tile.title as Text).data),
        ['SESSIONS', 'ORDERS', 'USERS'],
      );

      expect(find.text('https://api.example.com/users'), findsOneWidget);
      expect(find.text('GET'), findsOneWidget);
      expect(find.text('POST'), findsOneWidget);
      expect(find.text('200'), findsOneWidget);
      expect(find.text('500'), findsOneWidget);
      expect(find.text('Err'), findsOneWidget, reason: 'no status code');
      expect(find.text('250 ms'), findsNWidgets(2));
      expect(find.text('10:20.30'), findsOneWidget, reason: 'no response');
    });

    testWidgets('Clear All asks for confirmation', (tester) async {
      await pumpInspectorApp(tester);
      await openInspector(tester, requests: [users]);

      await tester.tap(find.text('Clear All'));
      await tester.pumpAndSettle();
      expect(find.text('Are you sure? 🤔'), findsOneWidget);
      await tester.tap(find.text('No'));
      await tester.pumpAndSettle();
      expect(find.text('USERS'), findsOneWidget);

      await tester.tap(find.text('Clear All'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();
      expect(find.text('USERS'), findsNothing);
      expect(find.text('No requests added yet'), findsOneWidget);
    });

    testWidgets('filters by URL while typing', (tester) async {
      await pumpInspectorApp(tester);
      await openInspector(tester, requests: [users, createOrder]);

      await tester.enterText(find.byType(TextField), 'orders');
      await tester.pumpAndSettle();
      expect(find.text('ORDERS'), findsOneWidget);
      expect(find.text('USERS'), findsNothing);

      await tester.enterText(find.byType(TextField), 'nothing-matches');
      await tester.pumpAndSettle();
      expect(
        find.text('No requests can be found with applied filters'),
        findsOneWidget,
      );

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();
      expect(find.text('ORDERS'), findsOneWidget);
      expect(find.text('USERS'), findsOneWidget);
      expect(InspectorController().searchUrlQuery, isEmpty);
    });

    testWidgets('filters dialog applies and clears method and status filters',
        (tester) async {
      await pumpInspectorApp(tester);
      await openInspector(tester, requests: [users, createOrder]);

      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();
      expect(find.text('Filter requests'), findsOneWidget);

      await tester.tap(find.text('Any'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('POST').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Status code'),
        '5x0',
      );
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      final controller = InspectorController();
      expect(controller.filterRequestMethod, RequestMethod.POST);
      expect(controller.filterStatusCode, 50, reason: 'digits only');
      expect(
        find.text('No requests can be found with applied filters'),
        findsOneWidget,
      );
      final filterIcon = tester.widget<Icon>(find.byIcon(Icons.filter_list));
      expect(filterIcon.color, Colors.orange);

      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();
      expect(find.text('POST'), findsOneWidget, reason: 'keeps the filter');
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      expect(controller.filterRequestMethod, isNull);
      expect(controller.filterStatusCode, isNull);
      expect(find.text('USERS'), findsOneWidget);
      expect(find.text('ORDERS'), findsOneWidget);
    });

    testWidgets('tapping a request opens its details', (tester) async {
      await pumpInspectorApp(tester);
      await openInspector(tester, requests: [users, createOrder]);

      await tester.tap(find.text('ORDERS'));
      await tester.pumpAndSettle();

      expect(InspectorController().selectedRequest, createOrder);
      expect(find.text('POST - ORDERS'), findsOneWidget);
      expect(find.text('Status: 500'), findsOneWidget);
      expect(find.text('Headers'), findsOneWidget);
      expect(find.text('Query Parameters'), findsOneWidget);
      expect(find.text('Request Body'), findsOneWidget);
      expect(find.text('Response Body'), findsOneWidget);
      expect(find.text('Run'), findsOneWidget);
      expect(find.byIcon(Icons.share), findsOneWidget);

      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      final selected = find.ancestor(
        of: find.text('ORDERS'),
        matching: find.byType(DecoratedBox),
      );
      expect(selected, findsWidgets, reason: 'selected item is outlined');
    });

    testWidgets('details tab asks to select a request first', (tester) async {
      await pumpInspectorApp(tester);
      await openInspector(tester, requests: [users]);

      await tester.tap(find.text('Request Details'));
      await tester.pumpAndSettle();

      expect(
        find.text('Please select a request first to view details'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.share), findsNothing);
    });
  });

  group('Inspector menu', () {
    testWidgets('toggles dark mode', (tester) async {
      await pumpInspectorApp(tester);
      await openInspector(tester);
      expect(inspectorBrightness(tester), Brightness.dark);

      await openMenu(tester);
      await tester.tap(find.text('Dark Mode'));
      await tester.pumpAndSettle();
      await closeMenu(tester);

      expect(InspectorController().isDarkMode, isFalse);
      expect(inspectorBrightness(tester), Brightness.light);

      await openMenu(tester);
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      await closeMenu(tester);
      expect(InspectorController().isDarkMode, isTrue);
    });

    testWidgets('toggles the JSON tree view and child expansion',
        (tester) async {
      await pumpInspectorApp(tester);
      await openInspector(tester, requests: [users]);
      await tester.tap(find.text('USERS'));
      await tester.pumpAndSettle();
      expect(find.byType(JsonTreeView), findsWidgets);

      await openMenu(tester);
      await tester.tap(find.text('JSON Tree View'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Expand Children'));
      await tester.pumpAndSettle();
      await closeMenu(tester);

      final controller = InspectorController();
      expect(controller.isTreeView, isFalse);
      expect(controller.expandChildren, isFalse);
      expect(find.byType(JsonTreeView), findsNothing);
      expect(selectableTexts(tester), contains('  "name": "John"'));

      await openMenu(tester);
      final switches = find.byType(Switch);
      await tester.tap(switches.at(1));
      await tester.tap(switches.at(2));
      await tester.pumpAndSettle();
      await closeMenu(tester);
      expect(controller.isTreeView, isTrue);
      expect(controller.expandChildren, isTrue);
    });

    testWidgets('hides the stopper options without a navigatorKey',
        (tester) async {
      await pumpInspectorApp(tester);
      await openInspector(tester);

      await openMenu(tester);

      expect(find.text('Dark Mode'), findsOneWidget);
      expect(find.text('Requests Stopper'), findsNothing);
      expect(find.text('Responses Stopper'), findsNothing);
    });

    testWidgets('configures the request stopper', (tester) async {
      await pumpInspectorApp(tester, navigatorKey: GlobalKey());
      await openInspector(tester);

      await openMenu(tester);
      await tester.tap(find.text('Requests Stopper'));
      await tester.pumpAndSettle();
      expect(find.text('Request Stopper Filters'), findsOneWidget);

      await tester.tap(find.text('Any'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PUT').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'URL contains'),
        ' /users ',
      );
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      final controller = InspectorController();
      expect(controller.requestStopperEnabled, isTrue);
      expect(controller.requestStopperFilterMethod, RequestMethod.PUT);
      expect(controller.requestStopperFilterUrl, '/users');

      // Reopening shows the saved filters; Clear removes them.
      await tester.tap(find.text('Requests Stopper'));
      await tester.pumpAndSettle();
      expect(find.text('/users'), findsOneWidget);
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      expect(controller.hasRequestStopperFilters, isFalse);
      expect(controller.requestStopperEnabled, isTrue);

      await tester.tap(find.byType(Switch).at(3));
      await tester.pumpAndSettle();
      expect(controller.requestStopperEnabled, isFalse);
    });

    testWidgets('configures the response stopper', (tester) async {
      await pumpInspectorApp(tester, navigatorKey: GlobalKey());
      await openInspector(tester);

      await openMenu(tester);
      await tester.tap(find.text('Responses Stopper'));
      await tester.pumpAndSettle();
      expect(find.text('Response Stopper Filters'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'URL contains'),
        'orders',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Status code'),
        '404',
      );
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      final controller = InspectorController();
      expect(controller.responseStopperEnabled, isTrue);
      expect(controller.responseStopperFilterUrl, 'orders');
      expect(controller.responseStopperFilterStatusCode, 404);

      await tester.tap(find.text('Responses Stopper'));
      await tester.pumpAndSettle();
      expect(find.text('404'), findsOneWidget);
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      expect(controller.hasResponseStopperFilters, isFalse);

      await tester.tap(find.byType(Switch).at(4));
      await tester.pumpAndSettle();
      expect(controller.responseStopperEnabled, isFalse);
    });
  });

  group('Inspector sharing', () {
    setUp(FakeShareChannel.install);

    Future<void> openDetails(
        WidgetTester tester, RequestDetails request) async {
      await pumpInspectorApp(tester);
      await openInspector(tester, requests: [request]);
      await tester.tap(find.text(request.requestName));
      await tester.pumpAndSettle();
    }

    Future<void> shareAs(WidgetTester tester, String option) async {
      await tester.tap(find.byIcon(Icons.share));
      await tester.pumpAndSettle();
      expect(find.text('Share as Normal Log, cURL or HAR? 🤔'), findsOneWidget);
      await tester.tap(find.text(option));
      await tester.pumpAndSettle();
    }

    testWidgets('shares the cURL command over the share_plus channel',
        (tester) async {
      await openDetails(tester, createOrder);

      await shareAs(tester, 'cURL Command');

      final call = FakeShareChannel.calls.single;
      expect(call.method, 'share');
      expect(FakeShareChannel.lastSharedText, startsWith('curl -X POST'));
      expect((call.arguments as Map).keys, contains('originX'));
    });

    testWidgets('shares the normal log and both formats', (tester) async {
      await openDetails(tester, createOrder);

      await shareAs(tester, 'Normal Log');
      expect(FakeShareChannel.lastSharedText,
          contains('=[ url ]===================\n'));

      await shareAs(tester, 'Both');
      expect(FakeShareChannel.lastSharedText, contains('[cURL Command]'));
      expect(FakeShareChannel.calls, hasLength(2));
    });

    testWidgets('shares HAR as text', (tester) async {
      await openDetails(tester, createOrder);

      await shareAs(tester, 'HAR');
      expect(find.text('HAR format'), findsOneWidget);
      await tester.tap(find.text('HAR text copy'));
      await tester.pumpAndSettle();

      final har = jsonDecode(FakeShareChannel.lastSharedText!);
      expect(har['log']['version'], '1.2');
      expect(har['log']['entries'][0]['response']['status'], 500);
    });

    testWidgets('sharing can be cancelled', (tester) async {
      await openDetails(tester, createOrder);

      await tester.tap(find.byIcon(Icons.share));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      await shareAs(tester, 'HAR');
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(FakeShareChannel.calls, isEmpty);
    });

    testWidgets('WebSocket requests are not shared', (tester) async {
      await openDetails(
        tester,
        sampleRequest(
          requestName: 'live',
          requestMethod: RequestMethod.WS,
          url: 'wss://api.example.com/live',
        ),
      );

      await tester.tap(find.byIcon(Icons.share));
      await tester.pumpAndSettle();

      expect(find.text('Share as Normal Log, cURL or HAR? 🤔'), findsNothing);
      expect(FakeShareChannel.calls, isEmpty);
    });
  });
}
