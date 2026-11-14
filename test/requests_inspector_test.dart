import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:requests_inspector/requests_inspector.dart';

import 'helpers/inspector_app.dart';
import 'helpers/plugin_mocks.dart';

void main() {
  group('RequestsInspector', () {
    testWidgets('only renders the child when disabled', (tester) async {
      await pumpInspectorApp(tester, enabled: false);

      expect(find.text(hostAppText), findsOneWidget);
      expect(find.byType(PageView), findsNothing);
      expect(inspectorBanner, findsNothing);
    });

    testWidgets('wraps the child with the inspector and a banner',
        (tester) async {
      await pumpInspectorApp(tester);

      expect(find.text(hostAppText).hitTestable(), findsOneWidget);
      expect(find.byType(PageView), findsOneWidget);
      expect(inspectorBanner, findsOneWidget);
      expect(isInspectorShown, isFalse);
      expect(visibleInspectorTitle, findsNothing);
    });

    testWidgets('can hide the banner', (tester) async {
      await pumpInspectorApp(tester, hideInspectorBanner: true);

      expect(inspectorBanner, findsNothing);
      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('passes the default options to the controller', (tester) async {
      await pumpInspectorApp(
        tester,
        defaultIsDarkMode: false,
        defaultTreeViewEnabled: false,
        defaultExpandChildren: false,
      );

      final controller = InspectorController();
      expect(controller.isDarkMode, isFalse);
      expect(controller.isTreeView, isFalse);
      expect(controller.expandChildren, isFalse);
    });

    for (final mode in [ShowInspectorOn.LongPress, ShowInspectorOn.Both]) {
      testWidgets('opens on long press with $mode and closes with X',
          (tester) async {
        await pumpInspectorApp(tester, showInspectorOn: mode);

        await tester.longPress(find.text(hostAppText));
        await tester.pumpAndSettle();

        expect(isInspectorShown, isTrue);
        expect(visibleInspectorTitle, findsOneWidget);
        expect(find.text('No requests added yet'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        expect(isInspectorShown, isFalse);
        expect(find.text(hostAppText).hitTestable(), findsOneWidget);
      });
    }

    testWidgets('opens and closes through the controller', (tester) async {
      await pumpInspectorApp(tester);

      InspectorController().showInspector();
      await tester.pumpAndSettle();
      expect(visibleInspectorTitle, findsOneWidget);

      InspectorController().hideInspector();
      await tester.pumpAndSettle();
      expect(visibleInspectorTitle, findsNothing);
    });

    testWidgets('opens when the phone is shaken three times', (tester) async {
      // Create the singleton first: on the test host RequestsInspector would
      // fall back to long press because the platform is not Android/iOS.
      InspectorController(
        enabled: true,
        showInspectorOn: ShowInspectorOn.Shaking,
      );
      await pumpInspectorApp(tester, showInspectorOn: ShowInspectorOn.Shaking);
      await tester.pump();
      expect(FakeSensors.isListening, isTrue);

      // The detector throttles on the wall clock (500 ms between shakes),
      // and platform messages are delivered by the real event loop.
      for (var i = 0; i < 3; i++) {
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 600));
          FakeSensors.emit(gForce: 3);
          await Future<void>.delayed(Duration.zero);
        });
      }
      await tester.pumpAndSettle();

      expect(isInspectorShown, isTrue);
      expect(visibleInspectorTitle, findsOneWidget);
    });

    testWidgets('does not open on long press with ShowInspectorOn.Shaking',
        (tester) async {
      InspectorController(
        enabled: true,
        showInspectorOn: ShowInspectorOn.Shaking,
      );
      await pumpInspectorApp(tester, showInspectorOn: ShowInspectorOn.Shaking);

      await tester.longPress(find.text(hostAppText));
      await tester.pumpAndSettle();

      expect(isInspectorShown, isFalse);
    });

    knownBug(
        'the controller falls back to LongPress on web/desktop, but the '
        'GestureDetector checks the original ShowInspectorOn.Shaking, so the '
        'inspector cannot be opened at all '
        '(requests_inspector_widget.dart:70).', () {
      testWidgets('falls back to long press where shaking is not supported',
          (tester) async {
        // flutter test runs on a desktop host, like web/desktop apps.
        await pumpInspectorApp(
          tester,
          showInspectorOn: ShowInspectorOn.Shaking,
        );

        await tester.longPress(find.text(hostAppText));
        await tester.pumpAndSettle();

        expect(isInspectorShown, isTrue);
      });
    });

    knownBug(
        'the WillPopScope sits above the host MaterialApp, so no route ever '
        'consults it: Android back pops the host page hidden behind the '
        'inspector (requests_inspector_widget.dart:66).', () {
      testWidgets('system back does not pop the host app behind the inspector',
          (tester) async {
        final navigatorKey = GlobalKey<NavigatorState>();
        await pumpInspectorApp(tester, navigatorKey: navigatorKey);
        navigatorKey.currentState!.push(MaterialPageRoute<void>(
          builder: (_) => const Text('Second page'),
        ));
        await tester.pumpAndSettle();
        await openInspector(tester);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(find.text('Second page'), findsOneWidget);
      });
    });
  });
}
