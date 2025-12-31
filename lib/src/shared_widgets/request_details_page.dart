import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:requests_inspector/requests_inspector.dart';
import 'package:requests_inspector/src/json_pretty_converter.dart';

import '../helpers/inspector_helper.dart';
import '../helpers/search_helper.dart';
import '../json_tree_view_widget.dart';
import 'highlighted_text.dart';
import 'search_widget.dart';

class _SearchState {
  final bool isTreeView;
  final bool isDarkMode;
  final String searchQuery;
  final bool expandChildren;

  _SearchState({
    required this.isTreeView,
    required this.isDarkMode,
    required this.searchQuery,
    required this.expandChildren,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _SearchState &&
          runtimeType == other.runtimeType &&
          isTreeView == other.isTreeView &&
          isDarkMode == other.isDarkMode &&
          searchQuery == other.searchQuery &&
          expandChildren == other.expandChildren;

  @override
  int get hashCode =>
      isTreeView.hashCode ^
      isDarkMode.hashCode ^
      searchQuery.hashCode ^
      expandChildren.hashCode;
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
                  const SizedBox(height: 8),
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
        expandChildren: controller.expandChildren,
      ),
      builder: (context, state, _) {
        final query = state.searchQuery;

        var currentOffset = 0;

        final sentTimeText = InspectorHelper.extractTimeText(request.sentTime);
        var timeAndUrlText = 'Sent at: $sentTimeText';

        if (request.receivedTime != null) {
          final receivedTimeText =
              InspectorHelper.extractTimeText(request.receivedTime!);
          final durationText = InspectorHelper.calculateDuration(
              request.sentTime, request.receivedTime!);
          timeAndUrlText +=
              '\nReceived at: $receivedTimeText\nDuration: $durationText';
        }

        timeAndUrlText += '\n\nURL: ${request.url}';

        final timeAndUrlMatches =
            SearchHelper.findMatches(text: timeAndUrlText, query: query).length;
        final timeAndUrlOffset = currentOffset;
        currentOffset += timeAndUrlMatches;

        final headersPretty = request.headers != null
            ? JsonPrettyConverter().convert(request.headers)
            : '';
        final headersMatches =
            SearchHelper.findMatches(text: headersPretty, query: query).length;
        final headersOffset = currentOffset;
        currentOffset += headersMatches;

        final queryParamsPretty = request.queryParameters != null
            ? JsonPrettyConverter().convert(request.queryParameters)
            : '';
        final queryParamsMatches =
            SearchHelper.findMatches(text: queryParamsPretty, query: query)
                .length;
        final queryParamsOffset = currentOffset;
        currentOffset += queryParamsMatches;

        final requestBodyPretty = request.requestBody != null
            ? JsonPrettyConverter().convert(request.requestBody)
            : '';
        final requestBodyMatches =
            SearchHelper.findMatches(text: requestBodyPretty, query: query)
                .length;
        final requestBodyOffset = currentOffset;
        currentOffset += requestBodyMatches;

        final graphqlVarsPretty = request.graphqlRequestVars != null
            ? JsonPrettyConverter().convert(request.graphqlRequestVars)
            : '';
        final graphqlVarsMatches =
            SearchHelper.findMatches(text: graphqlVarsPretty, query: query)
                .length;
        final graphqlVarsOffset = currentOffset;
        currentOffset += graphqlVarsMatches;

        final responseBodyPretty = request.responseBody != null
            ? JsonPrettyConverter().convert(request.responseBody)
            : '';
        final responseBodyMatches =
            SearchHelper.findMatches(text: responseBodyPretty, query: query)
                .length;
        final responseBodyOffset = currentOffset;
        currentOffset += responseBodyMatches;

        return Selector<InspectorController, int>(
          selector: (_, controller) => controller.currentMatchIndex,
          builder: (context, currentMatchIndex, _) {
            final isUrlActive = currentMatchIndex >= timeAndUrlOffset &&
                currentMatchIndex < timeAndUrlOffset + timeAndUrlMatches;
            final isHeadersActive = currentMatchIndex >= headersOffset &&
                currentMatchIndex < headersOffset + headersMatches;
            final isQueryParamsActive =
                currentMatchIndex >= queryParamsOffset &&
                    currentMatchIndex < queryParamsOffset + queryParamsMatches;
            final isRequestBodyActive =
                currentMatchIndex >= requestBodyOffset &&
                    currentMatchIndex < requestBodyOffset + requestBodyMatches;
            final isGraphqlActive = currentMatchIndex >= graphqlVarsOffset &&
                currentMatchIndex < graphqlVarsOffset + graphqlVarsMatches;
            final isResponseBodyActive = currentMatchIndex >=
                    responseBodyOffset &&
                currentMatchIndex < responseBodyOffset + responseBodyMatches;

            return ListView(
              padding:
                  const EdgeInsets.only(left: 12.0, right: 12.0, bottom: 96.0),
              children: [
                _buildExpandableSection(
                  context: context,
                  txtCopy: JsonPrettyConverter().convert(request.url),
                  initiallyExpanded: isUrlActive,
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
                      searchQuery: query,
                      isDarkMode: state.isDarkMode,
                      matchIndexOffset: timeAndUrlOffset,
                    ),
                  ],
                ),
                if (request.headers != null)
                  _buildExpandableSection(
                    context: context,
                    txtCopy: headersPretty,
                    title: 'Headers',
                    initiallyExpanded: isHeadersActive,
                    children: _buildDataBlock(
                      request.headers,
                      isTreeView: state.isTreeView,
                      isDarkMode: state.isDarkMode,
                      searchQuery: query,
                      matchIndexOffset: headersOffset,
                      expandChildren: state.expandChildren,
                    ),
                  ),
                if (request.queryParameters != null)
                  _buildExpandableSection(
                    context: context,
                    txtCopy: queryParamsPretty,
                    title: 'Query Parameters',
                    initiallyExpanded: isQueryParamsActive,
                    children: _buildDataBlock(
                      request.queryParameters,
                      isTreeView: state.isTreeView,
                      isDarkMode: state.isDarkMode,
                      searchQuery: query,
                      matchIndexOffset: queryParamsOffset,
                      expandChildren: state.expandChildren,
                    ),
                  ),
                if (request.requestBody != null)
                  _buildExpandableSection(
                    context: context,
                    txtCopy: requestBodyPretty,
                    title:
                        'Request Body${request.requestBody is FormData ? " (Form Data)" : ""}',
                    initiallyExpanded: isRequestBodyActive,
                    children: _buildDataBlock(
                      request.requestBody,
                      isTreeView: state.isTreeView,
                      isDarkMode: state.isDarkMode,
                      searchQuery: query,
                      matchIndexOffset: requestBodyOffset,
                      expandChildren: state.expandChildren,
                    ),
                  ),
                if (request.graphqlRequestVars != null)
                  _buildExpandableSection(
                    context: context,
                    txtCopy: graphqlVarsPretty,
                    title: 'GraphQL Request Vars',
                    initiallyExpanded: isGraphqlActive,
                    children: _buildDataBlock(
                      request.graphqlRequestVars,
                      isTreeView: state.isTreeView,
                      isDarkMode: state.isDarkMode,
                      searchQuery: query,
                      matchIndexOffset: graphqlVarsOffset,
                      expandChildren: state.expandChildren,
                    ),
                  ),
                if (request.responseBody != null)
                  _buildExpandableSection(
                    context: context,
                    txtCopy: responseBodyPretty,
                    title: 'Response Body',
                    initiallyExpanded: isResponseBodyActive,
                    children: _buildDataBlock(
                      request.responseBody,
                      isTreeView: state.isTreeView,
                      isDarkMode: state.isDarkMode,
                      searchQuery: query,
                      matchIndexOffset: responseBodyOffset,
                      expandChildren: state.expandChildren,
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  // ... (keeping other methods, updating _buildDataBlock below)

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
            key: initiallyExpanded ? ValueKey('${title}_expanded') : null,
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
    required int matchIndexOffset,
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
        matchIndexOffset: matchIndexOffset,
        style: const TextStyle(fontSize: 16.0),
      ),
    );
  }

  List<Widget> _buildDataBlock(
    dynamic data, {
    required bool isTreeView,
    required bool isDarkMode,
    required String searchQuery,
    required int matchIndexOffset,
    required bool expandChildren,
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
              matchIndexOffset: matchIndexOffset,
              expandChildren: expandChildren,
            )
          : _buildSelectableText(
              data,
              searchQuery: searchQuery,
              isDarkMode: isDarkMode,
              matchIndexOffset: matchIndexOffset,
            ),
    ];
  }

  Widget _buildSelectableText(
    dynamic text, {
    required String searchQuery,
    required bool isDarkMode,
    required int matchIndexOffset,
  }) {
    final prettyprint = JsonPrettyConverter().convert(text);
    final lines = prettyprint.split('\n');

    if (lines.isEmpty) return const SizedBox();

    // If only one line, return as before (optimization)
    if (lines.length == 1) {
      return Padding(
        padding: const EdgeInsets.all(6.0),
        child: HighlightedText(
          text: prettyprint,
          searchQuery: searchQuery,
          isDarkMode: isDarkMode,
          matchIndexOffset: matchIndexOffset,
        ),
      );
    }

    // If multiple lines, build a specific widget for each line so we can scroll to them
    final children = <Widget>[];
    var currentOffset = matchIndexOffset;

    for (final line in lines) {
      final matchesCount =
          SearchHelper.findMatches(text: line, query: searchQuery).length;

      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 1.0),
          child: HighlightedText(
            text: line,
            searchQuery: searchQuery,
            isDarkMode: isDarkMode,
            matchIndexOffset: currentOffset,
          ),
        ),
      );

      currentOffset += matchesCount;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
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
