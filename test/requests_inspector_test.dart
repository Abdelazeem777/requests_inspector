import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:requests_inspector/requests_inspector.dart';

import 'helpers/fakes.dart';
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

    testWidgets('wraps the child with the inspector and a banner', (
      tester,
    ) async {
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
      testWidgets('opens on long press with $mode and closes with X', (
        tester,
      ) async {
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

    // flutter test uses TargetPlatform.android unless a variant overrides it.
    testWidgets('opens when the phone is shaken three times', (tester) async {
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

    testWidgets(
      'does not open on long press with ShowInspectorOn.Shaking',
      (tester) async {
        await pumpInspectorApp(
          tester,
          showInspectorOn: ShowInspectorOn.Shaking,
        );

        await tester.longPress(find.text(hostAppText));
        await tester.pumpAndSettle();

        expect(isInspectorShown, isFalse);
        expect(FakeSensors.isListening, isTrue);
      },
      variant: mobilePlatforms,
    );

    // Web uses the same fallback (kIsWeb), checked on the example app.
    testWidgets(
      'falls back to long press where shaking is not supported',
      (tester) async {
        await pumpInspectorApp(
          tester,
          showInspectorOn: ShowInspectorOn.Shaking,
        );

        await tester.longPress(find.text(hostAppText));
        await tester.pumpAndSettle();

        expect(isInspectorShown, isTrue);
        expect(FakeSensors.isListening, isFalse);
      },
      variant: TargetPlatformVariant.desktop(),
    );
  });

  group('RequestsInspector system back', () {
    late GlobalKey<NavigatorState> navigatorKey;

    setUp(() => navigatorKey = GlobalKey<NavigatorState>());

    void pushHostPage(Widget page) => navigatorKey.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => page),
    );

    testWidgets('does not pop the host app behind the inspector', (
      tester,
    ) async {
      await pumpInspectorApp(tester, navigatorKey: navigatorKey);
      pushHostPage(const Text('Second page'));
      await tester.pumpAndSettle();
      await openInspector(tester);

      await systemBack(tester);

      // Back closes the inspector first...
      expect(isInspectorShown, isFalse);
      expect(find.text('Second page'), findsOneWidget);

      // ...and then reaches the host app again.
      await systemBack(tester);

      expect(find.text('Second page'), findsNothing);
      expect(find.text(hostAppText).hitTestable(), findsOneWidget);
    });

    testWidgets('leaves the host app on its first page as before', (
      tester,
    ) async {
      final calls = recordSystemNavigator(tester);
      bool appLeft() => calls.any((c) => c.method == 'SystemNavigator.pop');
      await pumpInspectorApp(tester, navigatorKey: navigatorKey);
      await openInspector(tester);

      await systemBack(tester);
      expect(isInspectorShown, isFalse);
      expect(appLeft(), isFalse);

      await systemBack(tester);
      expect(appLeft(), isTrue);
    });

    testWidgets('closes a dialog open in the inspector before the inspector', (
      tester,
    ) async {
      await pumpInspectorApp(tester, navigatorKey: navigatorKey);
      await openInspector(tester);
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();
      expect(find.text('Filter requests'), findsOneWidget);

      await systemBack(tester);

      expect(find.text('Filter requests'), findsNothing);
      expect(isInspectorShown, isTrue);

      await systemBack(tester);
      expect(isInspectorShown, isFalse);

      // It doesn't come back with the inspector.
      await openInspector(tester);
      expect(find.text('Filter requests'), findsNothing);
    });

    testWidgets('closes the inspector menu before the inspector', (
      tester,
    ) async {
      await pumpInspectorApp(tester, navigatorKey: navigatorKey);
      await openInspector(tester);
      // The test font is wider than the fixed-width menu rows.
      tester.platformDispatcher.textScaleFactorTestValue = 0.7;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      expect(find.text('Dark Mode'), findsOneWidget);

      await systemBack(tester);

      expect(find.text('Dark Mode'), findsNothing);
      expect(isInspectorShown, isTrue);
    });

    testWidgets('closes a stopper dialog while the inspector is hidden', (
      tester,
    ) async {
      final dio = inspectedDio(FakeHttpClientAdapter.json({'id': 1}));
      await pumpInspectorApp(tester, navigatorKey: navigatorKey);
      pushHostPage(const Text('Second page'));
      await tester.pumpAndSettle();
      InspectorController().requestStopperEnabled = true;

      final response = dio.get('/users');
      await tester.pumpAndSettle();
      expect(find.text('Send'), findsOneWidget);

      await systemBack(tester);
      await response;

      expect(find.text('Send'), findsNothing);
      expect(find.text('Second page'), findsOneWidget);
      expect(isInspectorShown, isFalse);
    });

    testWidgets("keeps the host app's PopScope working", (tester) async {
      var blockedPops = 0;
      await pumpInspectorApp(tester, navigatorKey: navigatorKey);
      pushHostPage(
        PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) => blockedPops++,
          child: const Text('Unsaved changes'),
        ),
      );
      await tester.pumpAndSettle();

      // With the inspector open, back only closes the inspector.
      await openInspector(tester);
      await systemBack(tester);
      expect(isInspectorShown, isFalse);
      expect(blockedPops, 0);

      // Then the host app gets it, as without the inspector.
      await systemBack(tester);
      expect(blockedPops, 1);
      expect(find.text('Unsaved changes'), findsOneWidget);
    });

    testWidgets('closes the inspector before a Router-based host app pops', (
      tester,
    ) async {
      final delegate = _PagesRouterDelegate(['Home', 'Second page']);
      await tester.pumpWidget(
        RequestsInspector(
          child: MaterialApp.router(
            routerDelegate: delegate,
            backButtonDispatcher: RootBackButtonDispatcher(),
          ),
        ),
      );
      await openInspector(tester);

      await systemBack(tester);
      expect(isInspectorShown, isFalse);
      expect(delegate.pages, ['Home', 'Second page']);

      await systemBack(tester);
      expect(delegate.pages, ['Home']);
    });

    // Android predictive back (enableOnBackInvokedCallback, the default when
    // targeting Android 16): back only reaches Flutter while the framework
    // says it handles it.
    testWidgets('makes the framework handle back while the inspector is open', (
      tester,
    ) async {
      final calls = recordSystemNavigator(tester);
      List<Object?> handlesBack() => [
        for (final call in calls)
          if (call.method == 'SystemNavigator.setFrameworkHandlesBack')
            call.arguments,
      ];
      await pumpInspectorApp(tester, navigatorKey: navigatorKey);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      pushHostPage(const Text('Second page'));
      await tester.pumpAndSettle();
      expect(handlesBack().last, isTrue);

      navigatorKey.currentState!.pop();
      await tester.pumpAndSettle();
      expect(handlesBack().last, isFalse);

      await openInspector(tester);
      expect(handlesBack().last, isTrue);

      // The inspector's own dialogs don't override it.
      calls.clear();
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();
      await systemBack(tester);
      expect(find.text('Filter requests'), findsNothing);
      expect(handlesBack(), isEmpty);
    });

    testWidgets('closes the inspector on a predictive back gesture', (
      tester,
    ) async {
      await pumpInspectorApp(tester, navigatorKey: navigatorKey);
      await openInspector(tester);

      await predictiveBackGesture(tester);

      expect(isInspectorShown, isFalse);
      expect(find.text(hostAppText).hitTestable(), findsOneWidget);
    });

    knownBug(
      'the predictive back route transition of a pushed host page handles '
      'the back gesture itself (it never reaches didPopRoute), so the '
      'hidden host page pops and the inspector stays open. Button backs '
      'and the host app\'s first page are fine.',
      () {
        testWidgets('a predictive back gesture does not pop the host app', (
          tester,
        ) async {
          await pumpInspectorApp(tester, navigatorKey: navigatorKey);
          pushHostPage(const Text('Second page'));
          await tester.pumpAndSettle();
          await openInspector(tester);

          await predictiveBackGesture(tester);

          expect(isInspectorShown, isFalse);
          expect(find.text('Second page'), findsOneWidget);
        });
      },
    );

    knownBug('inside MaterialApp.builder, RequestsInspector registers its back '
        "handler after the host app's, so back pops the hidden host page "
        'first. Wrap the MaterialApp instead (as in the README).', () {
      testWidgets('back closes the inspector when placed in builder', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigatorKey,
            builder: (_, child) =>
                RequestsInspector(navigatorKey: navigatorKey, child: child!),
            home: const Text(hostAppText),
          ),
        );
        pushHostPage(const Text('Second page'));
        await tester.pumpAndSettle();
        await openInspector(tester);

        await systemBack(tester);

        expect(isInspectorShown, isFalse);
        expect(find.text('Second page'), findsOneWidget);
      });
    });
  });

  group('RequestsInspector accessibility', () {
    testWidgets('keeps the host app visible to accessibility services', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpInspectorApp(tester);

      expect(find.semantics.byLabel(hostAppText), findsOneWidget);
      // The hidden inspector page is not, not even its edge (its "All" tab)
      // that the PageView keeps on screen. (find.semantics searches the live
      // semantics tree; find.bySemanticsLabel can match a dropped node.)
      expect(find.semantics.byLabel('All'), findsNothing);
      expect(find.semantics.byLabel('Clear All'), findsNothing);

      // The inspector page is accessible while it is shown...
      await openInspector(tester);
      expect(find.semantics.byLabel(RegExp('^Inspector')), findsOneWidget);
      expect(find.semantics.byLabel('Clear All'), findsOneWidget);
      expect(
        tester.getSemantics(find.byIcon(Icons.close)),
        containsSemantics(isButton: true, tooltip: 'Close inspector'),
      );
      // ...and the host app behind it is not.
      expect(find.semantics.byLabel(hostAppText), findsNothing);

      InspectorController().hideInspector();
      await tester.pumpAndSettle();
      expect(find.semantics.byLabel(hostAppText), findsOneWidget);
      expect(find.semantics.byLabel('All'), findsNothing);
      semantics.dispose();
    });
  });
}

/// A [Router] host app with a fixed list of pages.
class _PagesRouterDelegate extends RouterDelegate<Object>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<Object> {
  _PagesRouterDelegate(List<String> pages) : pages = [...pages];

  final List<String> pages;

  @override
  final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) => Navigator(
    key: navigatorKey,
    pages: [
      for (final page in pages)
        MaterialPage<void>(key: ValueKey(page), child: Text(page)),
    ],
    onDidRemovePage: (page) {
      pages.remove((page.key! as ValueKey<String>).value);
      notifyListeners();
    },
  );

  @override
  Future<void> setNewRoutePath(Object configuration) async {}
}
