import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../requests_inspector.dart';

class RequestItemWidget extends StatelessWidget {
  const RequestItemWidget({
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

