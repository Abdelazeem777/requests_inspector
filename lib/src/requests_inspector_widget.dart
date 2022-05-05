import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import '../requests_inspector.dart';

///You can show the Inspector by **Shaking** your phone.
class RequestsInspector extends StatelessWidget {
  const RequestsInspector({
    Key? key,
    this.enabled = false,
    this.hideInspectorBanner = false,
    this.showInspectorOn = ShowInspectorOn.Shaking,
    required Widget child,
  })  : _child = child,
        super(key: key);

  ///Require hot restart for showing its change
  final bool enabled;
  final bool hideInspectorBanner;
  final ShowInspectorOn showInspectorOn;
  final Widget _child;

  @override
  Widget build(BuildContext context) {
    var widget = enabled
        ? ChangeNotifierProvider(
            create: (context) => InspectorController(
              enabled: enabled,
              showInspectorOn: _isSupportShaking()
                  ? showInspectorOn
                  : ShowInspectorOn.LongPress,
            ),
            builder: (context, _) {
              final inspectorController = context.read<InspectorController>();
              return WillPopScope(
                onWillPop: () async =>
                    inspectorController.pageController.page == 0,
                child: GestureDetector(
                  onLongPress: inspectorController.showInspector,
                  child: PageView(
                    controller: inspectorController.pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _child,
                      const _Inspector(),
                    ],
                  ),
                ),
              );
            },
          )
        : _child;

    if (!hideInspectorBanner && enabled)
      widget = Banner(
        message: 'INSPECTOR',
        textDirection: TextDirection.ltr,
        location: BannerLocation.topEnd,
        child: widget,
      );

    if (enabled)
      widget = MaterialApp(
        debugShowCheckedModeBanner: false,
        home: widget,
      );

    return widget;
  }

  bool _isSupportShaking() =>
      kIsWeb ? false : Platform.isAndroid || Platform.isIOS;
}

class _Inspector extends StatelessWidget {
  const _Inspector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(),
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
        onTap: onTap,
      ),
    );
  }

  Widget _buildSelectedTab(BuildContext context, {required int selectedTab}) {
    return selectedTab == 0
        ? _buildAllRequests(context)
        : _buildSelectedTabRequests();
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
                itemBuilder: (context, index) => _RequestItemWidget(
                  request: allRequests[index],
                  onTap: (request) =>
                      inspectorController.selectedRequested = request,
                ),
              ),
      ),
    );
  }

  Widget _buildSelectedTabRequests() {
    return const _RequestDetailsPage();
  }
}

class _RequestItemWidget extends StatelessWidget {
  const _RequestItemWidget({
    Key? key,
    required RequestDetails request,
    required ValueChanged<RequestDetails> onTap,
  })  : _request = request,
        _onTap = onTap,
        super(key: key);

  final RequestDetails _request;
  final ValueChanged<RequestDetails> _onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: _request.statusCode == null
          ? Colors.red[400]
          : _request.statusCode! > 299
              ? Colors.red[400]
              : Colors.green[400],
      leading: Text(_request.requestMethod.name),
      title: Text(_request.requestName),
      subtitle: Text(_request.url),
      trailing: Text(_request.statusCode?.toString() ?? 'Err'),
      onTap: () => _onTap(_request),
    );
  }
}

class _RequestDetailsPage extends StatelessWidget {
  const _RequestDetailsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Selector<InspectorController, RequestDetails?>(
        selector: (_, inspectorController) =>
            inspectorController.selectedRequested,
        builder: (context, selectedRequest, _) => selectedRequest == null
            ? const Center(child: Text('No request selected'))
            : _buildRequestDetails(context, selectedRequest),
      ),
    );
  }

  Widget _buildRequestDetails(BuildContext context, RequestDetails request) {
    return ListView(
      children: [
        _buildRequestNameAndStatus(
          method: request.requestMethod,
          requestName: request.requestName,
          statusCode: request.statusCode,
        ),
        _buildRequestSentTime(request.sentTime),
        _buildTitle('URL'),
        _buildSelectableText(request.url),
        ..._buildHeadersBlock(request.headers),
        ..._buildQueryBlock(request.queryParameters),
        ..._buildRequestBodyBlock(request.requestBody),
        ..._buildResponseBodyBlock(request.responseBody),
      ].mapIndexed(_buildBackgroundColor).toList(),
    );
  }

  Widget _buildBackgroundColor(index, item) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: index.isOdd ? Colors.grey[100] : const Color(0xFF000000),
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
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _createRequestName(method, requestName),
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
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
    return (method?.name == null ? '' : method!.name + ': ') +
        (requestName ?? 'No name');
  }

  Widget _buildRequestSentTime(DateTime sentTime) {
    final sentTimeText = _extractTimeText(sentTime);
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        'Sent at: $sentTimeText',
        style: const TextStyle(fontSize: 16.0),
      ),
    );
  }

  String _extractTimeText(DateTime sentTime) {
    final sentTimeText =
        sentTime.toIso8601String().split('T').last.substring(0, 8);
    return sentTimeText;
  }

  Iterable<Widget> _buildHeadersBlock(headers) {
    if (headers == null) return [];
    if ((headers is Map || headers is String || headers is List) &&
        headers.isEmpty) return [];

    return [
      _buildTitle('Headers'),
      _buildSelectableText(headers),
      const SizedBox(height: 8.0),
    ];
  }

  Iterable<Widget> _buildQueryBlock(queryParameters) {
    if (queryParameters == null) return [];
    if ((queryParameters is Map ||
            queryParameters is String ||
            queryParameters is List) &&
        queryParameters.isEmpty) return [];

    return [
      _buildTitle('Parameters'),
      _buildSelectableText(queryParameters),
    ];
  }

  Iterable<Widget> _buildRequestBodyBlock(requestBody) {
    if (requestBody == null) return [];
    if ((requestBody is Map || requestBody is String || requestBody is List) &&
        requestBody.isEmpty) return [];

    return [
      _buildTitle('RequestBody'),
      _buildSelectableText(requestBody),
    ];
  }

  Iterable<Widget> _buildResponseBodyBlock(responseBody) {
    if (responseBody == null) return [];
    if ((responseBody is Map ||
            responseBody is String ||
            responseBody is List) &&
        responseBody.isEmpty) return [];

    return [
      _buildTitle('ResponseBody'),
      _buildSelectableText(responseBody),
    ];
  }

  Widget _buildSelectableText(text) {
    late final String prettyprint;
    if (text is Map || text is String || text is List)
      prettyprint = _convertToPrettyJsonFromMapOrJson(text);
    else if (text is FormData)
      prettyprint = 'FormData:\n' + _convertToPrettyFromFormData(text);
    else
      prettyprint = text.toString();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SelectableText(prettyprint),
    );
  }

  String _convertToPrettyJsonFromMapOrJson(text) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(text);
  }

  String _convertToPrettyFromFormData(FormData text) {
    final map = {
      for (final e in text.fields) e.key: e.value,
      for (final e in text.files) e.key: e.value.filename
    };

    return _convertToPrettyJsonFromMapOrJson(map);
  }

  Widget _buildTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
