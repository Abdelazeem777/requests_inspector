import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:requests_inspector/requests_inspector.dart';

const hostAppText = 'Host app';

/// Pumps a small host app wrapped in [RequestsInspector].
///
/// The [RequestsInspector] creates (and on teardown disposes) the
/// [InspectorController] singleton, so tests can use `InspectorController()`.
Future<void> pumpInspectorApp(
  WidgetTester tester, {
  bool enabled = true,
  ShowInspectorOn showInspectorOn = ShowInspectorOn.Both,
  bool hideInspectorBanner = false,
  GlobalKey<NavigatorState>? navigatorKey,
  bool defaultIsDarkMode = true,
  bool defaultTreeViewEnabled = true,
  bool defaultExpandChildren = true,
  Widget? home,
  Size surfaceSize = const Size(800, 1600),
}) async {
  tester.view
    ..physicalSize = surfaceSize
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(RequestsInspector(
    enabled: enabled,
    showInspectorOn: showInspectorOn,
    hideInspectorBanner: hideInspectorBanner,
    navigatorKey: navigatorKey,
    defaultIsDarkMode: defaultIsDarkMode,
    defaultTreeViewEnabled: defaultTreeViewEnabled,
    defaultExpandChildren: defaultExpandChildren,
    child: MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: home ?? const Scaffold(body: Center(child: Text(hostAppText))),
    ),
  ));
}

/// Adds [requests] (oldest first) and shows the inspector.
Future<void> openInspector(
  WidgetTester tester, {
  List<RequestDetails> requests = const [],
}) async {
  final controller = InspectorController();
  requests.forEach(controller.addNewRequest);
  controller.showInspector();
  await tester.pumpAndSettle();
}

/// The "INSPECTOR" corner banner added by [RequestsInspector].
final inspectorBanner = find.byWidgetPredicate(
  (widget) => widget is Banner && widget.message == 'INSPECTOR',
);

/// Whether the inspector page is the one on screen.
bool get isInspectorShown => InspectorController().pageController.page == 1;

/// The inspector title, only while it is actually on screen.
Finder get visibleInspectorTitle =>
    find.textContaining('Inspector').hitTestable();

/// Highlighted search matches (all [SelectableText]s on screen).
List<TextSpan> highlightedSpans(WidgetTester tester) {
  final spans = <TextSpan>[];
  for (final widget
      in tester.widgetList<SelectableText>(find.byType(SelectableText))) {
    widget.textSpan?.visitChildren((span) {
      if (span is TextSpan &&
          span.text != null &&
          span.style?.backgroundColor != null) {
        spans.add(span);
      }
      return true;
    });
  }
  return spans;
}

/// The plain text of every [SelectableText] on screen.
List<String> selectableTexts(WidgetTester tester) => [
      for (final widget
          in tester.widgetList<SelectableText>(find.byType(SelectableText)))
        widget.data ?? widget.textSpan!.toPlainText(),
    ];

/// Declares widget tests for a known bug as skipped, with a reason.
///
/// `testWidgets(skip:)` only takes a bool, so the reason goes on a group.
/// Run them with `flutter test --run-skipped` to check a fix.
void knownBug(String reason, void Function() body) =>
    group('(known bug)', body, skip: 'Known bug: $reason');

/// Android and iOS, where [RequestsInspector] listens to the accelerometer.
final mobilePlatforms =
    TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS});

/// A system back (Android back button, browser back button), as sent by the
/// platform when the framework handles back.
Future<void> systemBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

/// A full Android predictive back swipe from the left edge.
Future<void> predictiveBackGesture(WidgetTester tester) async {
  Future<void> send(String method, [Map<String, Object?>? arguments]) =>
      tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.backGesture.name,
        SystemChannels.backGesture.codec
            .encodeMethodCall(MethodCall(method, arguments)),
        (_) {},
      );

  await send('startBackGesture', {
    'touchOffset': <double>[5, 300],
    'progress': 0.0,
    'swipeEdge': 0,
  });
  await tester.pump();
  await send('updateBackGestureProgress', {
    'touchOffset': <double>[400, 300],
    'progress': 0.6,
    'swipeEdge': 0,
  });
  await tester.pump();
  await send('commitBackGesture');
  await tester.pumpAndSettle();
}

/// Records the `SystemNavigator.*` calls the app sends to the platform
/// (`setFrameworkHandlesBack`, `pop`, ...).
List<MethodCall> recordSystemNavigator(WidgetTester tester) {
  final calls = <MethodCall>[];
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method.startsWith('SystemNavigator.')) calls.add(call);
    return null;
  });
  addTearDown(
    () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
  );
  return calls;
}
