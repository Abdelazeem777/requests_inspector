import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'request_details.dart';
import 'requests_inspector_controller.dart';

class RequestsInspector extends StatelessWidget {
  const RequestsInspector({
    Key? key,
    this.enabled = false,
    required Widget child,
  })  : _child = child,
        super(key: key);

  ///Require hot restart for showing its change
  final bool enabled;
  final Widget _child;
  @override
  Widget build(BuildContext context) {
    return enabled
        ? MaterialApp(
            home: ChangeNotifierProvider(
              create: (context) => RequestsInspectorController(enabled),
              builder: (context, _) {
                final viewModel = Provider.of<RequestsInspectorController>(
                    context,
                    listen: false);
                return GestureDetector(
                  child: PageView(
                    controller: viewModel.pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _child,
                      const _Inspector(),
                    ],
                  ),
                  onLongPress: viewModel.showInspector,
                );
              },
            ),
          )
        : _child;
  }
}

class _Inspector extends StatelessWidget {
  const _Inspector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel =
        Provider.of<RequestsInspectorController>(context, listen: false);
    return Scaffold(
      appBar: _buildAppBar(viewModel),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar(RequestsInspectorController viewModel) {
    return AppBar(
      backgroundColor: Colors.black,
      title: const Text('Inspector'),
      leading: IconButton(
        onPressed: viewModel.hideInspector,
        icon: const Icon(Icons.close),
        color: Colors.white,
      ),
    );
  }

  Widget _buildBody() {
    return Selector<RequestsInspectorController, int>(
      selector: (_, viewModel) => viewModel.selectedTab,
      builder: (context, selectedTab, _) => Column(
        children: [
          _buildHeaderTabBar(context, selectedTab: selectedTab),
          _buildSelectedTab(context, selectedTab: selectedTab),
        ],
      ),
    );
  }

  Widget _buildHeaderTabBar(BuildContext context, {required int selectedTab}) {
    final viewModel =
        Provider.of<RequestsInspectorController>(context, listen: false);
    return Row(
      children: [
        _buildTabItem(
          title: 'All requests',
          isSelected: selectedTab == 0,
          onTap: () => viewModel.selectedTab = 0,
        ),
        _buildTabItem(
          title: 'SelectedTab requests',
          isSelected: selectedTab == 1,
          onTap: () => viewModel.selectedTab = 1,
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
          color: isSelected ? Colors.black : Colors.grey[700],
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(color: isSelected ? Colors.white : Colors.black),
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
    final viewModel =
        Provider.of<RequestsInspectorController>(context, listen: false);
    return Expanded(
      child: Selector<RequestsInspectorController, List<RequestDetails>>(
        selector: (_, viewModel) => viewModel.requestsList,
        shouldRebuild: (previous, next) => true,
        builder: (context, allRequests, _) => ListView.builder(
          itemCount: allRequests.length,
          itemBuilder: (context, index) => _RequestItemWidget(
            request: allRequests[index],
            onTap: (request) => viewModel.selectedRequested = request,
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
      tileColor: (_request.statusCode ?? 0) > 299
          ? Colors.red[400]
          : Colors.green[400],
      leading: Text(_request.requestMethod),
      title: Text(_request.requestName ?? _request.url),
      subtitle: _request.requestName != null ? Text(_request.url) : null,
      trailing: Text(_request.statusCode.toString()),
      onTap: () => _onTap(_request),
    );
  }
}

class _RequestDetailsPage extends StatelessWidget {
  const _RequestDetailsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Selector<RequestsInspectorController, RequestDetails?>(
        selector: (_, viewModel) => viewModel.selectedRequested,
        builder: (context, selectedRequest, _) => selectedRequest == null
            ? const Center(child: Text('no request selected'))
            : _buildRequestDetails(context, selectedRequest),
      ),
    );
  }

  Widget _buildRequestDetails(BuildContext context, RequestDetails request) {
    return ListView(
      children: [
        _buildRequestNameAndStatus(request.requestName, request.statusCode),
        _buildRequestSentTime(request.sentTime),
        _buildTitle('URL'),
        _buildSelectableText(request.url),
        const SizedBox(height: 8.0),
        _buildTitle('Headers'),
        _buildSelectableText(request.headers),
        const SizedBox(height: 8.0),
        if (request.requestBody != null) ...[
          _buildTitle('RequestBody'),
          _buildSelectableText(request.requestBody),
        ],
        const SizedBox(height: 8.0),
        _buildTitle('ResponseBody'),
        _buildSelectableText(request.responseBody),
      ],
    );
  }

  Widget _buildRequestNameAndStatus(String? requestName, int? statusCode) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              requestName ?? '',
              style:
                  const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            color:
                (statusCode ?? 0) > 299 ? Colors.red[400] : Colors.green[400],
            child: Text(
              statusCode.toString(),
              style: const TextStyle(fontSize: 18.0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestSentTime(DateTime sentTime) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        'Sent at: ${sentTime.toIso8601String().split('T').last}',
        style: const TextStyle(fontSize: 16.0),
      ),
    );
  }

  Widget _buildSelectableText(text) {
    late final String prettyprint;
    if (text is Map || text is String)
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
      child: Text(title,
          style: const TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          )),
    );
  }
}
