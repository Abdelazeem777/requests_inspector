import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_json_view/flutter_json_view.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:requests_inspector/src/json_pretty_converter.dart';
import 'package:requests_inspector/src/request_stopper_editor_dialog.dart';
import 'package:requests_inspector/src/response_stopper_editor_dialog.dart';
import '../requests_inspector.dart';

///You can show the Inspector by **Shaking** your phone.
class RequestsInspector extends StatelessWidget {
  /// Pass your `navigatorKey` of your MaterialApp to enable Request & Response `Stopper` Dialogs.
  /// And if you don't want to use it, you can pass it as `null`.
  const RequestsInspector({
    super.key,
    bool enabled = false,
    bool hideInspectorBanner = false,
    bool enableExpandableJsonView = true,
    ShowInspectorOn showInspectorOn = ShowInspectorOn.Both,
    required Widget child,
    required GlobalKey<NavigatorState>? navigatorKey,
  })  : _enabled = enabled,
        _hideInspectorBanner = hideInspectorBanner,
        _showInspectorOn = showInspectorOn,
        _child = child,
        _navigatorKey = navigatorKey,
        _enableExpandableJsonView = enableExpandableJsonView;

  ///Require hot restart for showing its change
  final bool _enabled;
  final bool _hideInspectorBanner;
  final ShowInspectorOn _showInspectorOn;
  final Widget _child;
  final bool _enableExpandableJsonView;

  final GlobalKey<NavigatorState>? _navigatorKey;

  @override
  Widget build(BuildContext context) {
    var widget = _enabled
        ? ChangeNotifierProvider(
            create: (context) => InspectorController(
              enableExpandableJsonView: _enableExpandableJsonView,
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

    if (!_hideInspectorBanner && _enabled)
      widget = Banner(
        message: 'INSPECTOR',
        textDirection: TextDirection.ltr,
        location: BannerLocation.topEnd,
        child: widget,
      );

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

class _Inspector extends StatelessWidget {
  const _Inspector({
    super.key,
    GlobalKey<NavigatorState>? navigatorKey,
  }) : _navigatorKey = navigatorKey;

  final GlobalKey<NavigatorState>? _navigatorKey;

  bool showStopperDialogsAllowed() => _navigatorKey?.currentContext != null;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: Theme.of(context).copyWith(useMaterial3: false),
      home: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(context),
        body: _buildBody(),
        floatingActionButton: _buildShareFloatingButton(),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final inspectorController = context.read<InspectorController>();

    return AppBar(
      backgroundColor: Colors.black,
      title: const Text('Inspector 🕵'),
      leading: IconButton(
        onPressed: inspectorController.hideInspector,
        icon: const Icon(Icons.close),
        color: Colors.white,
      ),
      actions: [
        Selector<InspectorController, int>(
          selector: (_, inspectorController) => inspectorController.selectedTab,
          builder: (context, selectedTab, _) => selectedTab == 0
              ? TextButton(
                  onPressed: () => _showAreYouSureDialog(
                    context,
                    onYes: inspectorController.clearAllRequests,
                  ),
                  child: const Text(
                    'Clear All',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : _RunAgainButton(
                  key: ValueKey(inspectorController.selectedRequest.hashCode),
                  onTap: inspectorController.runAgain,
                ),
        ),
        _buildPopUpMenu(inspectorController),
      ],
    );
  }

  Widget _buildPopUpMenu(InspectorController inspectorController) {
    return PopupMenuButton(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      itemBuilder: (context) => [
        if (showStopperDialogsAllowed())
          PopupMenuItem(
            child: InkWell(
              onTap: () => inspectorController.userRequestStopperEnabled =
                  !inspectorController.userRequestStopperEnabled,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Stop Requests'),
                  Selector<InspectorController, bool>(
                    selector: (_, inspectorController) =>
                        inspectorController.userRequestStopperEnabled,
                    builder: (context, userRequestStopperEnabled, _) => Switch(
                      value: userRequestStopperEnabled,
                      activeColor: Colors.green,
                      activeTrackColor: Colors.grey[700],
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.grey[700],
                      onChanged: (value) =>
                          inspectorController.userRequestStopperEnabled = value,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (showStopperDialogsAllowed())
          PopupMenuItem(
            child: InkWell(
              onTap: () => inspectorController.userResponseStopperEnabled =
                  !inspectorController.userResponseStopperEnabled,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Stop Responses'),
                  Selector<InspectorController, bool>(
                    selector: (_, inspectorController) =>
                        inspectorController.userResponseStopperEnabled,
                    builder: (context, userResponseStopperEnabled, _) => Switch(
                      value: userResponseStopperEnabled,
                      activeColor: Colors.green,
                      activeTrackColor: Colors.grey[700],
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.grey[700],
                      onChanged: (value) => inspectorController
                          .userResponseStopperEnabled = value,
                    ),
                  ),
                ],
              ),
            ),
          ),
        PopupMenuItem(
          child: InkWell(
            onTap: () => inspectorController.enableExpandableJsonView =
                !inspectorController.enableExpandableJsonView,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Expandable Json view'),
                Selector<InspectorController, bool>(
                  selector: (_, inspectorController) =>
                      inspectorController.enableExpandableJsonView,
                  builder: (context, showExpandableJsonView, _) => Switch(
                    value: showExpandableJsonView,
                    activeColor: Colors.green,
                    activeTrackColor: Colors.grey[700],
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.grey[700],
                    onChanged: (value) =>
                        inspectorController.enableExpandableJsonView = value,
                  ),
                ),
              ],
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
          const Divider(height: 1),
          _buildSelectedTab(context, selectedTab: selectedTab),
        ],
      ),
    );
  }

//TODO: HERE!
  Widget _buildHeaderTabBar(BuildContext context, {required int selectedTab}) {
    final inspectorController = context.read<InspectorController>();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTabItem(
          title: 'All requests',
          isSelected: selectedTab == 0,
          onTap: () => inspectorController.selectedTab = 0,
        ),
        _buildTabItem(
          title: 'SelectedTab requests',
          isSelected: selectedTab == 1,
          onTap: () => inspectorController.selectedTab = 1,
        ),
      ],
    );
  }

  Widget _buildTabItem({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12.0),
          alignment: Alignment.center,
          color: isSelected ? Colors.black : Colors.grey[700],
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w300,
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
    final inspectorController = context.read<InspectorController>();
    return Expanded(
      child: Selector<InspectorController, List<RequestDetails>>(
        selector: (_, controller) => controller.requestsList,
        shouldRebuild: (previous, next) => true,
        builder: (context, allRequests, _) => allRequests.isEmpty
            ? const Center(child: Text('No requests added yet'))
            : ListView.builder(
                itemCount: allRequests.length,
                itemBuilder: (context, index) {
                  final request = allRequests[index];
                  return _RequestItemWidget(
                    isSelected: inspectorController.selectedRequest == request,
                    request: request,
                    onTap: (request) =>
                        inspectorController.selectedRequest = request,
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
            child: const Text('Yes'),
            onPressed: () {
              Navigator.of(context).pop();
              onYes();
            },
          ),
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('No'),
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
        title: const Text('Normal Log or CURL command? 🤔'),
        content: const Text(
            'The CURL command is more useful for exporting to Postman or run it again from terminal'),
        actions: [
          TextButton(
            child: const Text('CURL Command'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Normal Log'),
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
  }) : super(key: key);

  final Future<void> Function() onTap;

  @override
  _RunAgainButtonState createState() => _RunAgainButtonState();
}

class _RunAgainButtonState extends State<_RunAgainButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
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
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Run', style: TextStyle(color: Colors.white)),
                Icon(Icons.play_arrow, color: Colors.white),
              ],
            ));
  }

  void _setBusy() => setState(() => _isLoading = true);
  void _setReady() => setState(() => _isLoading = false);
}

class _RequestItemWidget extends StatelessWidget {
  const _RequestItemWidget({
    super.key,
    required bool isSelected,
    required RequestDetails request,
    required ValueChanged<RequestDetails> onTap,
  })  : _isSelected = isSelected,
        _request = request,
        _onTap = onTap;

  final bool _isSelected;
  final RequestDetails _request;
  final ValueChanged<RequestDetails> _onTap;

  @override
  Widget build(BuildContext context) {
    Widget child = ListTile(
      tileColor: _request.statusCode == null
          ? Colors.red[400]
          : _request.statusCode! > 299
              ? Colors.red[400]
              : Colors.green[400],
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
      onTap: () => _onTap(_request),
    );

    if (_isSelected)
      child = DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 2.0),
        ),
        child: child,
      );
    return child;
  }
}

class _RequestDetailsPage extends StatelessWidget {
  const _RequestDetailsPage();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Selector<InspectorController, RequestDetails?>(
        selector: (_, inspectorController) =>
            inspectorController.selectedRequest,
        shouldRebuild: (previous, next) => true,
        builder: (context, selectedRequest, _) => selectedRequest == null
            ? const Center(child: Text('No request selected'))
            : _buildRequestDetails(context, selectedRequest),
      ),
    );
  }

  Widget _buildRequestDetails(BuildContext context, RequestDetails request) {
    final _inspectorController = context.read<InspectorController>();
    return ListView(
      padding: const EdgeInsets.only(bottom: 96.0),
      children: [
        _buildRequestNameAndStatus(
          method: request.requestMethod,
          requestName: request.requestName,
          statusCode: request.statusCode,
        ),
        _buildRequestSentTimeAndDuration(
          request.sentTime,
          request.receivedTime,
        ),
        _buildTitle('URL'),
        _buildSelectableText(request.url),
        ..._buildHeadersBlock(
            request.headers, _inspectorController.enableExpandableJsonView),
        ..._buildQueryBlock(request.queryParameters,
            _inspectorController.enableExpandableJsonView),
        ..._buildRequestBodyBlock(
            request.requestBody, _inspectorController.enableExpandableJsonView),
        ..._buildResponseBodyBlock(request.responseBody,
            _inspectorController.enableExpandableJsonView),
      ].mapIndexed(_buildBackgroundColor).toList(),
    );
  }

  Widget _buildBackgroundColor(index, item) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: index.isEven
            ? const Color.fromARGB(255, 208, 208, 208)
            : const Color(0xFFFFFFFF),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: item,
      ),
    );
  }

  Widget _buildRequestNameAndStatus({
    RequestMethod? method,
    String? requestName,
    int? statusCode,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _createRequestName(method, requestName),
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            color: statusCode == null
                ? Colors.red[400]
                : statusCode > 299
                    ? Colors.red[400]
                    : Colors.green[400],
            child: Text(
              statusCode?.toString() ?? 'Err',
              style: const TextStyle(fontSize: 18.0),
            ),
          ),
        ],
      ),
    );
  }

  String _createRequestName(RequestMethod? method, String? requestName) {
    return (method?.name == null ? '' : '${method!.name}: ') +
        (requestName ?? 'No name');
  }

  Widget _buildRequestSentTimeAndDuration(
    DateTime sentTime,
    DateTime? receivedTime,
  ) {
    final sentTimeText = _extractTimeText(sentTime);
    var text = 'Sent at: $sentTimeText';

    if (receivedTime != null) {
      final durationText = _calculateDuration(sentTime, receivedTime);
      final receivedTimeText = _extractTimeText(receivedTime);
      text += '\nReceived at: $receivedTimeText\nDuration: $durationText';
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16.0),
      ),
    );
  }

  Iterable<Widget> _buildHeadersBlock(headers, bool showExpandableJsonView) {
    if (headers == null) return [];
    if ((headers is Map || headers is String || headers is List) &&
        headers.isEmpty) return [];

    return [
      _buildTitle('Headers'),
      _buildJsonBlock(showExpandableJsonView, headers)
    ];
  }

  Widget _buildJsonBlock(bool showExpandableJsonView, body) {
    return showExpandableJsonView
        ? body.runtimeType != String
            ? _buildJsonViewer(body)
            : _buildSelectableText(body)
        : _buildSelectableText(body);
  }

  Iterable<Widget> _buildQueryBlock(
    queryParameters,
    bool showExpandableJsonView,
  ) {
    if (queryParameters == null) return [];
    if ((queryParameters is Map ||
            queryParameters is String ||
            queryParameters is List) &&
        queryParameters.isEmpty) return [];

    return [
      _buildTitle('Parameters'),
      _buildJsonBlock(showExpandableJsonView, queryParameters)
    ];
  }

  Iterable<Widget> _buildRequestBodyBlock(
      requestBody, bool showExpandableJsonView) {
    if (requestBody == null) return [];
    if ((requestBody is Map || requestBody is String || requestBody is List) &&
        requestBody.isEmpty) return [];

    return [
      _buildTitle('RequestBody'),
      _buildJsonBlock(showExpandableJsonView, requestBody)
    ];
  }

  Iterable<Widget> _buildResponseBodyBlock(
    responseBody,
    bool showExpandableJsonView,
  ) {
    if (responseBody == null) return [];
    if ((responseBody is Map ||
            responseBody is String ||
            responseBody is List) &&
        responseBody.isEmpty) return [];
    return [
      _buildTitle('ResponseBody'),
      _buildJsonBlock(showExpandableJsonView, responseBody)
    ];
  }

  Widget _buildJsonViewer(text) {
    final prettyprint = JsonPrettyConverter().convert(text);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: JsonView.string(
        prettyprint,
        keyName: '{...}',
        listKeyName: '[...]',
        theme: _buildJsonViewTheme(),
      ),
    );
  }

  JsonViewTheme _buildJsonViewTheme() {
    return const JsonViewTheme(
      backgroundColor: Colors.transparent,
      keyStyle: TextStyle(
        color: Colors.black54,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      separator: Text(
        ' : ',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      doubleStyle: TextStyle(
        color: Colors.green,
        fontSize: 16,
      ),
      intStyle: TextStyle(
        color: Colors.green,
        fontSize: 16,
      ),
      stringStyle: TextStyle(
        color: Colors.green,
        fontSize: 16,
      ),
      boolStyle: TextStyle(
        color: Colors.green,
        fontSize: 16,
      ),
      closeIcon: Icon(
        Icons.arrow_drop_down,
        color: Colors.green,
        size: 24,
      ),
      openIcon: Icon(
        Icons.arrow_drop_up,
        color: Colors.green,
        size: 24,
      ),
    );
  }

  Widget _buildSelectableText(text) {
    final prettyprint = JsonPrettyConverter().convert(text);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SelectableText(prettyprint),
    );
  }

  Widget _buildTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
        ),
      ),
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
