import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:requests_inspector/requests_inspector.dart';
import 'package:requests_inspector/src/json_pretty_converter.dart';

import '../json_tree_view_widget.dart';

class RequestDetailsPage extends StatelessWidget {
  const RequestDetailsPage({super.key});

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
            children: _buildDataBlock(request.headers),
          ),
        if (request.queryParameters != null)
          _buildExpandableSection(
            context: context,
            initiallyExpanded: false,
            txtCopy: JsonPrettyConverter().convert(request.queryParameters),
            title: 'Query Parameters',
            children: _buildDataBlock(request.queryParameters),
          ),
        if (request.requestBody != null)
          _buildExpandableSection(
            context: context,
            initiallyExpanded: false,
            txtCopy: JsonPrettyConverter().convert(request.requestBody),
            title: 'Request Body',
            children: _buildDataBlock(request.requestBody),
          ),
        if (request.responseBody != null)
          _buildExpandableSection(
            context: context,
            txtCopy: JsonPrettyConverter().convert(request.responseBody),
            title: 'Response Body',
            children: _buildDataBlock(request.responseBody),
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

  /// A generic function to build a content block based on provided data.
  /// It handles null/empty checks and switches between JsonTreeView and SelectableText
  /// based on the InspectorController's isTreeView state.
  Iterable<Widget> _buildDataBlock(dynamic data) {
    if (data == null) return [];

    // Check for empty collections or strings
    if ((data is Map || data is String || data is List) && data.isEmpty) {
      return [];
    }

    return [
      Selector<InspectorController, bool>(
        selector: (_, controller) => controller.isTreeView,
        builder: (context, isTreeView, __) {
          return isTreeView
              ? JsonTreeView(data)
              : _buildSelectableText(data); // Assuming _buildSelectableText is accessible
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

Color? _specifyStatusCodeColor(int? statusCode) {
  if (statusCode == null) return Colors.red[400];
  if (statusCode > 399) return Colors.red[400];
  if (statusCode > 299) return Colors.yellow[400];
  return Colors.green[400];
}

