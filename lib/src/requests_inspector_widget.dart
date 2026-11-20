import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:requests_inspector/src/request_stopper_editor_dialog.dart';
import 'package:requests_inspector/src/response_stopper_editor_dialog.dart';
import 'package:requests_inspector/src/shared_widgets/inspector.dart';
import '../requests_inspector.dart';

///You can show the Inspector by **Shaking** your phone.
class RequestsInspector extends StatelessWidget {
  /// Pass your `navigatorKey` of your MaterialApp to enable Request & Response `Stopper` Dialogs.
  /// And if you don't want to use it, you can pass it as `null`.
  const RequestsInspector({
    super.key,
    bool enabled = true,
    bool hideInspectorBanner = false,
    ShowInspectorOn showInspectorOn = ShowInspectorOn.Both,
    required Widget child,
    bool defaultTreeViewEnabled = true,
    GlobalKey<NavigatorState>? navigatorKey,
    bool defaultExpandChildren = true,
    bool defaultIsDarkMode = true,
  })  : _enabled = enabled,
        _hideInspectorBanner = hideInspectorBanner,
        _showInspectorOn = showInspectorOn,
        _child = child,
        _navigatorKey = navigatorKey,
        _defaultTreeViewEnabled = defaultTreeViewEnabled,
        _defaultExpandChildren = defaultExpandChildren,
        _defaultIsDarkMode = defaultIsDarkMode;

  final bool _enabled;
  final bool _hideInspectorBanner;
  final ShowInspectorOn _showInspectorOn;
  final Widget _child;
  final bool _defaultTreeViewEnabled;
  final bool _defaultExpandChildren;
  final bool _defaultIsDarkMode;
  final GlobalKey<NavigatorState>? _navigatorKey;

  @override
  Widget build(BuildContext context) {
    final showInspectorOn =
        _isSupportShaking() ? _showInspectorOn : ShowInspectorOn.LongPress;
    var widget = _enabled
        ? ChangeNotifierProvider(
            create: (context) => InspectorController(
              enabled: _enabled,
              showInspectorOn: showInspectorOn,
              defaultTreeViewEnabled: _defaultTreeViewEnabled,
              defaultExpandChildren: _defaultExpandChildren,
              defaultIsDarkMode: _defaultIsDarkMode,
              onStoppingRequest: (requestDetails) => _showRequestEditorDialog(
                context,
                requestDetails: requestDetails,
              ),
              onStoppingResponse: (responseDetails) =>
                  _showResponseEditorDialog(
                context,
                responseDetails: responseDetails,
              ),
            ),
            lazy: false,
            builder: (context, _) {
              return _InspectorPages(
                navigatorKey: _navigatorKey,
                openOnLongPress: showInspectorOn != ShowInspectorOn.Shaking,
                child: _child,
              );
            },
          )
        : _child;

    if (!_hideInspectorBanner && _enabled) {
      widget = Banner(
        message: 'INSPECTOR',
        textDirection: TextDirection.ltr,
        location: BannerLocation.topEnd,
        child: widget,
      );
    }

    return Directionality(textDirection: TextDirection.ltr, child: widget);
  }

  // defaultTargetPlatform is the platform the app runs on (and, unlike
  // dart:io's Platform, follows debugDefaultTargetPlatformOverride in tests).
  bool _isSupportShaking() =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<RequestDetails?> _showRequestEditorDialog(
    BuildContext context, {
    required RequestDetails requestDetails,
  }) {
    if (_navigatorKey?.currentContext == null) return Future.value(null);
    if (!InspectorController().shouldStopRequest(requestDetails))
      return Future.value(null);

    return showDialog<RequestDetails?>(
      context: _navigatorKey!.currentContext!,
      builder: (context) =>
          RequestStopperEditorDialog(requestDetails: requestDetails),
    );
  }

  Future<ResponseDetails?> _showResponseEditorDialog(
    BuildContext context, {
    required ResponseDetails responseDetails,
  }) {
    if (_navigatorKey?.currentContext == null) return Future.value(null);
    if (!InspectorController().shouldStopResponse(responseDetails))
      return Future.value(null);

    return showDialog<ResponseDetails>(
      context: _navigatorKey!.currentContext!,
      builder: (context) =>
          ResponseStopperEditorDialog(responseDetails: responseDetails),
    );
  }
}

/// The host app and the inspector, as the two pages of a [PageView].
///
/// It also handles system back (the Android back button or gesture, the
/// browser back button) while the inspector is shown: back closes a dialog or
/// menu open in the inspector, or else the inspector, instead of letting the
/// host app pop the page hidden behind it.
///
/// A [PopScope] (or the deprecated `WillPopScope`) can't do this here: it only
/// applies inside a route, and [WidgetsBinding] notifies its observers in
/// registration order, so the host app's navigator would pop first. As their
/// ancestor, this widget registers before the host app and the inspector
/// (when [RequestsInspector] wraps the host's `MaterialApp`, not when it is
/// inside its `builder`).
class _InspectorPages extends StatefulWidget {
  const _InspectorPages({
    required this.navigatorKey,
    required this.openOnLongPress,
    required this.child,
  });

  final GlobalKey<NavigatorState>? navigatorKey;
  final bool openOnLongPress;
  final Widget child;

  @override
  State<_InspectorPages> createState() => _InspectorPagesState();
}

class _InspectorPagesState extends State<_InspectorPages>
    with WidgetsBindingObserver {
  final _inspectorNavigatorKey = GlobalKey<NavigatorState>();
  var _isInspectorShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _isInspectorShown = page != 0);

    // With Android predictive back, back only reaches Flutter while the
    // framework says it handles it, and on its first page the host app says
    // it doesn't: back would leave the app instead of closing the inspector.
    // (The host app updates it again on its next navigation.)
    if (_isInspectorShown) SystemNavigator.setFrameworkHandlesBack(true);
  }

  @override
  Future<bool> didPopRoute() async {
    if (!_isInspectorShown) return false;

    final inspectorNavigator = _inspectorNavigatorKey.currentState;
    if (inspectorNavigator != null && await inspectorNavigator.maybePop()) {
      return true;
    }

    InspectorController().hideInspector();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress:
          widget.openOnLongPress ? InspectorController().showInspector : null,
      child: PageView(
        controller: InspectorController().pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: _onPageChanged,
        // Only the page on screen is in the accessibility tree.
        children: [
          ExcludeSemantics(
            excluding: _isInspectorShown,
            child: widget.child,
          ),
          ExcludeSemantics(
            excluding: !_isInspectorShown,
            // The inspector is a second MaterialApp. Without its own semantics
            // container, the BlockSemantics of its route's ModalBarrier drops
            // everything painted before it, i.e. the whole host app, from the
            // accessibility tree.
            child: Semantics(
              container: true,
              child: Inspector(
                navigatorKey: widget.navigatorKey,
                inspectorNavigatorKey: _inspectorNavigatorKey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
