import 'package:flutter/material.dart';

class InspectorHelper {
  static String extractTimeText(DateTime sentTime) {
    var sentTimeText =
        sentTime.toIso8601String().split('T').last.substring(0, 8);
    sentTimeText = _replaceLastSeparatorWithDot(sentTimeText);
    return sentTimeText;
  }

  static String calculateDuration(DateTime sentTime, DateTime receivedTime) {
    final duration = receivedTime.difference(sentTime);

    if (duration.inMilliseconds < 1000) return '${duration.inMilliseconds} ms';
    if (duration.inSeconds < 60) return '${duration.inSeconds} s';
    if (duration.inMinutes < 60) return '${duration.inMinutes} m';
    if (duration.inHours < 24) return '${duration.inHours} h';
    return '${duration.inDays} d';
  }

  static String _replaceLastSeparatorWithDot(String sentTimeText) =>
      sentTimeText.replaceFirst(':', '.', 5);

  static Color? specifyStatusCodeColor(int? statusCode) {
    if (statusCode == null) return Colors.red[400];
    if (statusCode > 399) return Colors.red[400];
    if (statusCode > 299) return Colors.yellow[400];
    return Colors.green[400];
  }
}
