import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:requests_inspector/src/json_pretty_converter.dart';
import 'package:requests_inspector/src/request_stopper_editor_dialog.dart';
import 'package:requests_inspector/src/response_stopper_editor_dialog.dart';
import '../requests_inspector.dart';
import 'json_tree_view_widget.dart';

// Helper class for combining two values for a Selector
// Placed at top-level for better organization
class Tuple2<T1, T2> {
  final T1 item1;
  final T2 item2;

  const Tuple2(this.item1, this.item2);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tuple2 &&
          runtimeType == other.runtimeType &&
          item1 == other.item1 &&
          item2 == other.item2;

  @override
  int get hashCode => item1.hashCode ^ item2.hashCode;
}

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
    GlobalKey<NavigatorState>? navigatorKey,
  })  : _enabled = enabled,
        _hideInspectorBanner = hideInspectorBanner,
        _showInspectorOn = showInspectorOn,
        _child = child,
        _navigatorKey = navigatorKey;

  ///Require hot restart for showing its change
  final bool _enabled;
  final bool _hideInspectorBanner;
  final ShowInspectorOn _showInspectorOn;
  final Widget _child;

  final GlobalKey<NavigatorState>? _navigatorKey;

  @override
  Widget build(BuildContext context) {
    var widget = _enabled
        ? ChangeNotifierProvider(
            create: (context) => InspectorController(
              enabled: _enabled,
              showInspectorOn: _isSupportShaking()
                  ? _showInspectorOn
                  : ShowInspectorOn.LongPress,
              onStoppingRequest: (requestDetails) => _showRequestEditorDialog(
                context,
                requestDetails: requestDetails,
              ),
              onStoppingResponse: (responseData) => _showResponseEditorDialog(
                context,
                responseData: responseData,
              ),
            ),
            builder: (context, _) {
              final inspectorController = context.read<InspectorController>();
              return WillPopScope(
                onWillPop: () async =>
                    inspectorController.pageController.page == 0,
                child: GestureDetector(
                  onLongPress: _showInspectorOn != ShowInspectorOn.Shaking
                      ? inspectorController.showInspector
                      : null,
                  child: PageView(
                    controller: inspectorController.pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _child,
                      _Inspector(navigatorKey: _navigatorKey),
                    ],
                  ),
                ),
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

    return Directionality(
      textDirection: TextDirection.ltr,
      child: widget,
    );
  }

  bool _isSupportShaking() =>
      kIsWeb ? false : Platform.isAndroid || Platform.isIOS;

  Future<RequestDetails?> _showRequestEditorDialog(
    BuildContext context, {
    required RequestDetails requestDetails,
  }) {
    if (_navigatorKey?.currentContext == null) return Future.value(null);
    return showDialog<RequestDetails?>(
      context: _navigatorKey!.currentContext!,
      builder: (context) =>
          RequestStopperEditorDialog(requestDetails: requestDetails),
    );
  }

  Future _showResponseEditorDialog(
    BuildContext context, {
    required responseData,
  }) {
    if (_navigatorKey?.currentContext == null) return Future.value(null);

    return showDialog(
      context: _navigatorKey!.currentContext!,
      builder: (context) =>
          ResponseStopperEditorDialog(responseData: responseData),
    );
  }
}

class _Inspector extends StatefulWidget {
  const _Inspector({
    super.key,
    GlobalKey<NavigatorState>? navigatorKey,
  }) : _navigatorKey = navigatorKey;

  final GlobalKey<NavigatorState>? _navigatorKey;

  @override
  State<_Inspector> createState() => _InspectorState();
}

class _InspectorState extends State<_Inspector> {
  bool showStopperDialogsAllowed() =>
      widget._navigatorKey?.currentContext != null;

  @override
  Widget build(BuildContext context) {
    return Selector<InspectorController, bool>(
      selector: (_, controller) => controller.isDarkMode,
      builder: (context, isDarkMode, child) {
        return MaterialApp(
          theme: isDarkMode
              ? ThemeData.dark().copyWith(
                  colorScheme: ColorScheme.dark(
                    primary: Colors.grey[800]!,
                  ),
                )
              : ThemeData.light(),
          home: Scaffold(
            appBar: _buildAppBar(context),
            body: _buildBody(),
            floatingActionButton: _buildShareFloatingButton(),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    // Read the controller once for method calls that don't cause AppBar rebuilds.
    final inspectorCtrl = context.read<InspectorController>();

    return AppBar(
      // Use context.select for direct property access that triggers rebuilds
      backgroundColor: context.select((InspectorController c) => c.isDarkMode)
          ? Colors.black
          : Colors.white,
      title: const Text('Inspector 🕵️'),
      leading: IconButton(
        onPressed: inspectorCtrl.hideInspector,
        // Use context.select for direct property access that triggers rebuilds
        icon: Icon(Icons.close,
            color: context.select((InspectorController c) => c.isDarkMode)
                ? Colors.white
                : Colors.black87),
      ),
      actions: [
        // Consolidate selectors that depend on selectedTab and isDarkMode for the actions row.
        Selector<InspectorController, Tuple2<int, bool>>(
          selector: (_, controller) =>
              Tuple2(controller.selectedTab, controller.isDarkMode),
          builder: (context, data, _) {
            final selectedTab = data.item1;
            final isDarkMode = data.item2;

            return Row(
              children: [
                // JSON Tree Icon: Selector specifically for isTreeView and isDarkMode
                Selector<InspectorController, Tuple2<bool, bool>>(
                  selector: (_, controller) =>
                      Tuple2(controller.isTreeView, controller.isDarkMode),
                  builder: (context, iconData, __) {
                    final isTreeView = iconData.item1;
                    final iconIsDarkMode = iconData.item2;
                    return IconButton(
                      icon: isTreeView
                          ? Icon(Icons.text_fields,
                              color: iconIsDarkMode
                                  ? Colors.white
                                  : Colors.black87,
                              size: 20)
                          : Icon(Icons.account_tree_rounded,
                              color: iconIsDarkMode
                                  ? Colors.white
                                  : Colors.black87,
                              size: 20),
                      onPressed: inspectorCtrl
                          .toggleInspectorJsonView, // Use outer inspectorCtrl
                    );
                  },
                ),
                // Dark Mode Icon: Selector specifically for isDarkMode
                Selector<InspectorController, bool>(
                  selector: (_, controller) => controller.isDarkMode,
                  builder: (context, iconIsDarkMode, __) {
                    return IconButton(
                      icon: iconIsDarkMode
                          ? const Icon(Icons.wb_sunny,
                              color: Colors.white, size: 20)
                          : const Icon(Icons.brightness_2,
                              color: Colors.black87, size: 20),
                      onPressed: inspectorCtrl
                          .toggleInspectorTheme, // Use outer inspectorCtrl
                    );
                  },
                ),
                // Separator: Its margin depends on selectedTab
                Container(
                  width: 2,
                  height: 20,
                  color: Colors.grey[200],
                  margin: selectedTab == 0
                      ? null
                      : const EdgeInsets.only(right: 12),
                ),
                // Clear All / Run Again Button: Depends on selectedTab and isDarkMode
                selectedTab == 0
                    ? TextButton(
                        onPressed: () => _showAreYouSureDialog(
                          context,
                          onYes: inspectorCtrl
                              .clearAllRequests, // Use outer inspectorCtrl
                        ),
                        child: Text(
                          'Clear All',
                          style: TextStyle(
                              color:
                                  isDarkMode ? Colors.white : Colors.black87),
                        ),
                      )
                    : _RunAgainButton(
                        key: ValueKey(inspectorCtrl.selectedRequest.hashCode),
                        // Key for efficient updates
                        onTap: inspectorCtrl.runAgain,
                        // Use outer inspectorCtrl
                        isDarkMode: isDarkMode, // Pass theme state directly
                      ),
              ],
            );
          },
        ),
        _buildPopUpMenu(inspectorCtrl),
      ],
    );
  }

  Widget _buildPopUpMenu(InspectorController inspectorController) {
    return PopupMenuButton(
      icon: Selector<InspectorController, bool>(
        selector: (_, controller) => controller.isDarkMode,
        builder: (context, isDarkMode, __) => Icon(Icons.more_vert,
            color: isDarkMode ? Colors.white : Colors.black87),
      ),
      itemBuilder: (context) => [
        if (showStopperDialogsAllowed())
          PopupMenuItem(
            padding: EdgeInsets.zero,
            // Remove default padding for InkWell to fill
            child: InkWell(
              onTap: () => inspectorController.requestStopperEnabled =
                  !inspectorController.requestStopperEnabled,
              child: Padding(
                // Add padding back for content
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Requests Stopper'),
                    Selector<InspectorController, bool>(
                      selector: (_, inspectorController) =>
                          inspectorController.requestStopperEnabled,
                      builder: (context, requestStopperEnabled, _) => Switch(
                        value: requestStopperEnabled,
                        activeColor: Colors.green,
                        activeTrackColor: Colors.grey[700],
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.grey[700],
                        onChanged: (value) =>
                            inspectorController.requestStopperEnabled = value,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (showStopperDialogsAllowed())
          PopupMenuItem(
            padding: EdgeInsets.zero,
            // Remove default padding for InkWell to fill
            child: InkWell(
              onTap: () => inspectorController.responseStopperEnabled =
                  !inspectorController.responseStopperEnabled,
              child: Padding(
                // Add padding back for content
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Responses Stopper'),
                    Selector<InspectorController, bool>(
                      selector: (_, inspectorController) =>
                          inspectorController.responseStopperEnabled,
                      builder: (context, responseStopperEnabled, _) => Switch(
                        value: responseStopperEnabled,
                        activeColor: Colors.green,
                        activeTrackColor: Colors.grey[700],
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.grey[700],
                        onChanged: (value) =>
                            inspectorController.responseStopperEnabled = value,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBody() {
    return Selector<InspectorController, int>(
      selector: (_, inspectorController) => inspectorController.selectedTab,
      builder: (context, selectedTab, _) => Column(
        children: [
          _buildHeaderTabBar(context, selectedTab: selectedTab),
          _buildSelectedTab(context, selectedTab: selectedTab),
        ],
      ),
    );
  }

  Widget _buildHeaderTabBar(BuildContext context, {required int selectedTab}) {
    final inspectorController = context.read<InspectorController>();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTabItem(
          context: context,
          title: 'All',
          isSelected: selectedTab == 0,
          isLeft: true,
          onTap: () => inspectorController.selectedTab = 0,
        ),
        _buildTabItem(
          context: context,
          title: 'Request Details',
          isSelected: selectedTab == 1,
          isLeft: false,
          onTap: () => inspectorController.selectedTab = 1,
        ),
      ],
    );
  }

  Widget _buildTabItem({
    required String title,
    required bool isSelected,
    required bool isLeft,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12.0),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.select((InspectorController c) => c.isDarkMode)
                ? (isSelected ? Theme.of(context).primaryColor : Colors.black87)
                : (isSelected ? Theme.of(context).primaryColor : Colors.white),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: context.select((InspectorController c) => c.isDarkMode)
                  ? Colors.white
                  : (isSelected ? Colors.white : Colors.black87),
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w300,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTab(BuildContext context, {required int selectedTab}) {
    return selectedTab == 0
        ? _buildAllRequests(context)
        : const _RequestDetailsPage();
  }

  Widget _buildAllRequests(BuildContext context) {
    return Expanded(
      child: Selector<InspectorController, List<RequestDetails>>(
        selector: (_, controller) => controller.requestsList,
        shouldRebuild: (previous, next) => true,
        builder: (context, allRequests, _) => allRequests.isEmpty
            ? const Center(child: Text('No requests added yet'))
            : ListView.separated(
                padding:
                    const EdgeInsets.symmetric(vertical: 6.0, horizontal: 6.0),
                separatorBuilder: (_, __) => const SizedBox(height: 6.0),
                itemCount: allRequests.length,
                itemBuilder: (context, index) {
                  final request = allRequests[index];
                  return _RequestItemWidget(
                    request: request,
                    // Modified onTap to pass context and request
                    onTap: (itemContext, tappedRequest) {
                      itemContext.read<InspectorController>().selectedRequest =
                          tappedRequest;
                    },
                  );
                },
              ),
      ),
    );
  }

  Future<void> _showAreYouSureDialog(
    BuildContext context, {
    required VoidCallback onYes,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Are you sure? 🤔'),
        content:
            const Text('This will clear all requests added to the inspector'),
        actions: [
          TextButton(
            child: const Text(
              'Yes',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              onYes();
            },
          ),
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('No', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  Widget _buildShareFloatingButton() {
    return Selector<InspectorController, bool>(
      selector: (_, inspectorController) =>
          inspectorController.selectedTab == 1 &&
          inspectorController.selectedRequest != null,
      builder: (context, showShareButton, _) => showShareButton
          ? FloatingActionButton(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              child: const Icon(Icons.share),
              onPressed: () async {
                final box = context.findRenderObject() as RenderBox?;

                final controller = context.read<InspectorController>();
                final selectedRequest = controller.selectedRequest!;
                final isHttp = _isHttp(selectedRequest);

                final isCurl =
                    isHttp ? await _showDialogShareType(context) : false;

                if (isCurl == null) return;

                controller.shareSelectedRequest(
                  box == null
                      ? null
                      : box.localToGlobal(Offset.zero) & box.size,
                  isCurl,
                );
              })
          : const SizedBox(),
    );
  }

  bool _isHttp(RequestDetails selectedRequest) {
    return selectedRequest.requestMethod == RequestMethod.GET ||
        selectedRequest.requestMethod == RequestMethod.POST ||
        selectedRequest.requestMethod == RequestMethod.PUT ||
        selectedRequest.requestMethod == RequestMethod.PATCH ||
        selectedRequest.requestMethod == RequestMethod.DELETE;
  }

  Future<bool?> _showDialogShareType(BuildContext context) {
    return showDialog<bool?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Normal Log or cURL command? 🤔'),
        content: const Text(
            'The cURL command is more useful for exporting to Postman or run it again from terminal'),
        actions: [
          TextButton(
            child: const Text(
              'cURL Command',
              style: TextStyle(color: Colors.green),
            ),
            onPressed: () => Navigator.of(context).pop(true),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Normal Log',
              style: TextStyle(color: Colors.yellow),
            ),
          ),
        ],
      ),
    );
  }
}

class _RunAgainButton extends StatefulWidget {
  const _RunAgainButton({
    Key? key,
    required this.onTap,
    required this.isDarkMode, // Pass isDarkMode directly
  }) : super(key: key);

  final Future<void> Function() onTap;
  final bool isDarkMode; // New parameter

  @override
  _RunAgainButtonState createState() => _RunAgainButtonState();
}

class _RunAgainButtonState extends State<_RunAgainButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // No need for a Selector here, as isDarkMode is passed as a direct prop
    return _isLoading
        ? const Center(
            child: Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(color: Colors.white),
          ))
        : InkWell(
            onTap: () {
              _setBusy();
              widget.onTap().whenComplete(_setReady);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Run',
                    style: TextStyle(
                        color:
                            widget.isDarkMode ? Colors.white : Colors.black87)),
                Icon(Icons.play_arrow,
                    color: widget.isDarkMode ? Colors.white : Colors.black87),
              ],
            ),
          );
  }

  void _setBusy() => setState(() => _isLoading = true);

  void _setReady() => setState(() => _isLoading = false);
}

class _RequestItemWidget extends StatelessWidget {
  const _RequestItemWidget({
    super.key,
    // Removed isSelected from here, it will be calculated internally
    required RequestDetails request,
    // Changed onTap signature to accept BuildContext
    required void Function(BuildContext context, RequestDetails request) onTap,
  })  : _request = request,
        _onTap = onTap;

  // Removed _isSelected field
  final RequestDetails _request;
  final void Function(BuildContext context, RequestDetails request) _onTap;

  @override
  Widget build(BuildContext context) {
    // Crucial change: Use context.select to listen only to the selectedRequest for THIS item
    final isSelected = context.select<InspectorController, bool>(
      (controller) => controller.selectedRequest == _request,
    );

    Widget child = ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
      tileColor: _specifyStatusCodeColor(_request.statusCode),
      leading: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            _request.requestMethod.name,
            style: const TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            _request.receivedTime != null
                ? _calculateDuration(_request.sentTime, _request.receivedTime!)
                : _extractTimeText(_request.sentTime),
            style: TextStyle(color: Colors.grey[800]),
          ),
        ],
      ),
      title: Text(_request.requestName),
      subtitle: Text(_request.url),
      trailing: Text(
        _request.statusCode?.toString() ?? 'Err',
        style: const TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      // Pass the current context and the request to the onTap callback
      onTap: () => _onTap(context, _request),
    );

    if (isSelected) {
      // Use the locally derived isSelected
      child = DecoratedBox(
        decoration: BoxDecoration(
          border: context.select((InspectorController c) => c.isDarkMode)
              ? Border.all(color: Colors.white, width: 2.0)
              : Border.all(color: Colors.black, width: 2.0),
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: child,
      );
    }
    // This theme data copy will implicitly update if the main MaterialApp's theme changes,
    // as it's rebuilding as part of the _InspectorState's build method
    return Theme(
      data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light()),
      child: child,
    );
  }
}

Color? _specifyStatusCodeColor(int? statusCode) {
  if (statusCode == null) return Colors.red[400];
  if (statusCode > 399) return Colors.red[400];
  if (statusCode > 299) return Colors.yellow[400];
  return Colors.green[400];
}

class _RequestDetailsPage extends StatelessWidget {
  const _RequestDetailsPage();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Selector<InspectorController, RequestDetails?>(
        selector: (_, inspectorController) =>
            inspectorController.selectedRequest,
        shouldRebuild: (previous, next) => true, // Still good for list changes
        builder: (context, selectedRequest, _) => selectedRequest == null
            ? const Center(
                child: Text(
                    'Please select a request first to view details')) // Added const
            : _buildRequestDetails(context, selectedRequest),
      ),
    );
  }

  Widget _buildRequestDetails(BuildContext context, RequestDetails request) {
    return ListView(
      padding: const EdgeInsets.only(left: 12.0, right: 12.0, bottom: 96.0),
      children: [
        _buildExpandableSection(
          context: context,
          initiallyExpanded: false,
          txtCopy: JsonPrettyConverter().convert(request.url),
          titleWidget: _buildRequestNameAndStatus(
            method: request.requestMethod,
            requestName: request.requestName,
            statusCode: request.statusCode,
          ),
          children: [
            _buildRequestSentTimeAndDuration(
              request.sentTime,
              request.receivedTime,
              request.url,
            ),
          ],
        ),
        if (request.headers != null)
          _buildExpandableSection(
            context: context,
            initiallyExpanded: false,
            txtCopy: JsonPrettyConverter().convert(request.headers),
            title: 'Headers',
            children: _buildHeadersBlock(request.headers),
          ),
        if (request.queryParameters != null)
          _buildExpandableSection(
            context: context,
            initiallyExpanded: false,
            txtCopy: JsonPrettyConverter().convert(request.queryParameters),
            title: 'Query Parameters',
            children: _buildQueryBlock(request.queryParameters),
          ),
        if (request.requestBody != null)
          _buildExpandableSection(
            context: context,
            initiallyExpanded: false,
            txtCopy: JsonPrettyConverter().convert(request.requestBody),
            title: 'Request Body',
            children: _buildRequestBodyBlock(request.requestBody),
          ),
        if (request.responseBody != null)
          _buildExpandableSection(
            context: context,
            txtCopy: JsonPrettyConverter().convert(request.responseBody),
            title: 'Response Body',
            children: _buildResponseBodyBlock(request.responseBody),
          ),
      ],
    );
  }

  Widget _buildExpandableSection({
    required BuildContext context,
    String? title,
    required String txtCopy,
    Widget? titleWidget,
    required Iterable<Widget> children,
    bool? initiallyExpanded,
  }) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final borderColor = theme.dividerColor;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded ?? true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          childrenPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          expandedAlignment: Alignment.topLeft,
          title: Row(
            children: [
              Expanded(
                child: titleWidget ??
                    Text(
                      title ?? '',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              ),
              InkWell(
                child: const Icon(
                  Icons.copy,
                  color: Colors.grey,
                  size: 20,
                ),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: txtCopy));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                },
              ),
            ],
          ),
          backgroundColor: cardColor,
          children: [
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children.toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestSentTimeAndDuration(
    DateTime sentTime,
    DateTime? receivedTime,
    String url,
  ) {
    final sentTimeText = _extractTimeText(sentTime);
    var text = 'Sent at: $sentTimeText';

    if (receivedTime != null) {
      final durationText = _calculateDuration(sentTime, receivedTime);
      final receivedTimeText = _extractTimeText(receivedTime);
      text += '\nReceived at: $receivedTimeText\nDuration: $durationText';
    }

    text += '\n\nURL: $url';

    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: SelectableText(
        text,
        style: const TextStyle(fontSize: 16.0),
      ),
    );
  }

  Iterable<Widget> _buildHeadersBlock(headers) {
    if (headers == null) return [];
    if ((headers is Map || headers is String || headers is List) &&
        headers.isEmpty) return [];

    return [
      Selector<InspectorController, bool>(
        selector: (_, controller) => controller.isTreeView,
        builder: (context, isTreeView, __) {
          return isTreeView
              ? JsonTreeView(headers)
              : _buildSelectableText(headers);
        },
      )
    ];
  }

  Iterable<Widget> _buildQueryBlock(queryParameters) {
    if (queryParameters == null) return [];
    if ((queryParameters is Map ||
            queryParameters is String ||
            queryParameters is List) &&
        queryParameters.isEmpty) return [];

    return [
      Selector<InspectorController, bool>(
        selector: (_, controller) => controller.isTreeView,
        builder: (context, isTreeView, __) {
          return isTreeView
              ? JsonTreeView(queryParameters)
              : _buildSelectableText(queryParameters);
        },
      )
    ];
  }

  Iterable<Widget> _buildRequestBodyBlock(requestBody) {
    if (requestBody == null) return [];
    if ((requestBody is Map || requestBody is String || requestBody is List) &&
        requestBody.isEmpty) return [];

    return [
      Selector<InspectorController, bool>(
        selector: (_, controller) => controller.isTreeView,
        builder: (context, isTreeView, __) {
          return isTreeView
              ? JsonTreeView(requestBody)
              : _buildSelectableText(requestBody);
        },
      )
    ];
  }

  Iterable<Widget> _buildResponseBodyBlock(responseBody) {
    if (responseBody == null) return [];
    if ((responseBody is Map ||
            responseBody is String ||
            responseBody is List) &&
        responseBody.isEmpty) return [];

    return [
      Selector<InspectorController, bool>(
        selector: (_, controller) => controller.isTreeView,
        builder: (context, isTreeView, __) {
          return isTreeView
              ? JsonTreeView(responseBody)
              : _buildSelectableText(responseBody);
        },
      )
    ];
  }

  Widget _buildSelectableText(text) {
    final prettyprint = JsonPrettyConverter().convert(text);

    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: SelectableText(prettyprint),
    );
  }

  Widget _buildRequestNameAndStatus({
    required RequestMethod method,
    required String requestName,
    required int? statusCode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${method.name} - $requestName',
          style: const TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          'Status: ${statusCode ?? 'N/A'}',
          style: TextStyle(
            fontSize: 14.0,
            color: _specifyStatusCodeColor(statusCode),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

String _extractTimeText(DateTime sentTime) {
  var sentTimeText = sentTime.toIso8601String().split('T').last.substring(0, 8);
  sentTimeText = _replaceLastSeparatorWithDot(sentTimeText);
  return sentTimeText;
}

String _calculateDuration(DateTime sentTime, DateTime receivedTime) {
  final duration = receivedTime.difference(sentTime);

  if (duration.inMilliseconds < 1000) return '${duration.inMilliseconds} ms';
  if (duration.inSeconds < 60) return '${duration.inSeconds} s';
  if (duration.inMinutes < 60) return '${duration.inMinutes} m';
  if (duration.inHours < 24) return '${duration.inHours} h';
  return '${duration.inDays} d';
}

String _replaceLastSeparatorWithDot(String sentTimeText) =>
    sentTimeText.replaceFirst(':', '.', 5);
