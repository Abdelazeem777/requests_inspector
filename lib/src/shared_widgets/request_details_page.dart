import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:requests_inspector/requests_inspector.dart';
import 'package:requests_inspector/src/json_pretty_converter.dart';

import '../helpers/inspector_helper.dart';
import '../json_tree_view_widget.dart';
import 'highlighted_text.dart';
import 'search_widget.dart';

class _SearchState {
  final bool isTreeView;
  final bool isDarkMode;
  final String searchQuery;

  _SearchState({
    required this.isTreeView,
    required this.isDarkMode,
    required this.searchQuery,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _SearchState &&
          runtimeType == other.runtimeType &&
          isTreeView == other.isTreeView &&
          isDarkMode == other.isDarkMode &&
          searchQuery == other.searchQuery;

  @override
  int get hashCode => isTreeView.hashCode ^ isDarkMode.hashCode ^ searchQuery.hashCode;
}

class RequestDetailsPage extends StatelessWidget {
  const RequestDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Selector<InspectorController, RequestDetails?>(
        selector: (_, inspectorController) =>
            inspectorController.selectedRequest,
        shouldRebuild: (previous, next) => true,
        builder: (context, selectedRequest, _) => selectedRequest == null
            ? const Center(
                child: Text('Please select a request first to view details'),
              )
            : Column(
                children: [
                  Selector<InspectorController, bool>(
                    selector: (_, controller) => controller.isDarkMode,
                    builder: (context, isDarkMode, _) => SearchWidget(
                      isDarkMode: isDarkMode,
                    ),
                  ),
                  Expanded(
                    child: _buildRequestDetails(context, selectedRequest),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildRequestDetails(BuildContext context, RequestDetails request) {
    return Selector<InspectorController, _SearchState>(
      selector: (_, controller) => _SearchState(
        isTreeView: controller.isTreeView,
        isDarkMode: controller.isDarkMode,
        searchQuery: controller.searchQuery,
      ),
      builder: (context, state, _) {
        return ListView(
          padding: const EdgeInsets.only(left: 12.0, right: 12.0, bottom: 96.0),
          children: [
            _buildExpandableSection(
              context: context,
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
                  searchQuery: state.searchQuery,
                  isDarkMode: state.isDarkMode,
                ),
              ],
            ),
            if (request.headers != null)
              _buildExpandableSection(
                context: context,
                txtCopy: JsonPrettyConverter().convert(request.headers),
                title: 'Headers',
                children: _buildDataBlock(
                  request.headers,
                  isTreeView: state.isTreeView,
                  isDarkMode: state.isDarkMode,
                  searchQuery: state.searchQuery,
                ),
              ),
            if (request.queryParameters != null)
              _buildExpandableSection(
                context: context,
                txtCopy: JsonPrettyConverter().convert(request.queryParameters),
                title: 'Query Parameters',
                children: _buildDataBlock(
                  request.queryParameters,
                  isTreeView: state.isTreeView,
                  isDarkMode: state.isDarkMode,
                  searchQuery: state.searchQuery,
                ),
              ),
            if (request.requestBody != null)
              _buildExpandableSection(
                context: context,
                txtCopy: JsonPrettyConverter().convert(request.requestBody),
                title:
                    'Request Body${request.requestBody is FormData ? " (Form Data)" : ""}',
                children: _buildDataBlock(
                  request.requestBody,
                  isTreeView: state.isTreeView,
                  isDarkMode: state.isDarkMode,
                  searchQuery: state.searchQuery,
                ),
              ),
            if (request.graphqlRequestVars != null)
              _buildExpandableSection(
                context: context,
                txtCopy:
                    JsonPrettyConverter().convert(request.graphqlRequestVars),
                title: 'GraphQL Request Vars',
                children: _buildDataBlock(
                  request.graphqlRequestVars,
                  isTreeView: state.isTreeView,
                  isDarkMode: state.isDarkMode,
                  searchQuery: state.searchQuery,
                ),
              ),
            if (request.responseBody != null)
              _buildExpandableSection(
                context: context,
                txtCopy: JsonPrettyConverter().convert(request.responseBody),
                title: 'Response Body',
                children: _buildDataBlock(
                  request.responseBody,
                  isTreeView: state.isTreeView,
                  isDarkMode: state.isDarkMode,
                  searchQuery: state.searchQuery,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildExpandableSection({
    required BuildContext context,
    String? title,
    required String txtCopy,
    Widget? titleWidget,
    required List<Widget> children,
    bool initiallyExpanded = true,
  }) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final borderColor = theme.dividerColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DecoratedBox(
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
            initiallyExpanded: initiallyExpanded,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            childrenPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
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
                  child: const Icon(Icons.copy, color: Colors.grey, size: 20),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: txtCopy));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  },
                ),
              ],
            ),
            children: [
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestSentTimeAndDuration(
    DateTime sentTime,
    DateTime? receivedTime,
    String url, {
    required String searchQuery,
    required bool isDarkMode,
  }) {
    final sentTimeText = InspectorHelper.extractTimeText(sentTime);
    var text = 'Sent at: $sentTimeText';

    if (receivedTime != null) {
      final durationText = InspectorHelper.calculateDuration(
        sentTime,
        receivedTime,
      );
      final receivedTimeText = InspectorHelper.extractTimeText(receivedTime);
      text += '\nReceived at: $receivedTimeText\nDuration: $durationText';
    }

    text += '\n\nURL: $url';

    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: HighlightedText(
        text: text,
        searchQuery: searchQuery,
        isDarkMode: isDarkMode,
        style: const TextStyle(fontSize: 16.0),
      ),
    );
  }

  List<Widget> _buildDataBlock(
    dynamic data, {
    required bool isTreeView,
    required bool isDarkMode,
    required String searchQuery,
  }) {
    if (data == null) return [];

    if ((data is Map || data is String || data is List) && data.isEmpty) {
      return [];
    }

    return [
      isTreeView
          ? JsonTreeView(
              data,
              isDarkMode: isDarkMode,
              searchQuery: searchQuery,
            )
          : _buildSelectableText(
              data,
              searchQuery: searchQuery,
              isDarkMode: isDarkMode,
            ),
    ];
  }

  Widget _buildSelectableText(
    text, {
    required String searchQuery,
    required bool isDarkMode,
  }) {
    final prettyprint = JsonPrettyConverter().convert(text);
    

    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: HighlightedText(
        text: prettyprint,
        searchQuery: searchQuery,
        isDarkMode: isDarkMode,
      ),
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
          style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4.0),
        Text(
          'Status: ${statusCode ?? 'N/A'}',
          style: TextStyle(
            fontSize: 14.0,
            color: InspectorHelper.specifyStatusCodeColor(statusCode),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

}
