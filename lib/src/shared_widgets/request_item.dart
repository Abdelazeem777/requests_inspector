import 'package:flutter/material.dart';

import '../../requests_inspector.dart';
import '../helpers/inspector_helper.dart';

class RequestItemWidget extends StatelessWidget {
  const RequestItemWidget({
    super.key,
    required RequestDetails request,
    required bool isSelected,
    required bool isDarkMode,
    required void Function(BuildContext context, RequestDetails request) onTap,
  })  : _request = request,
        _isSelected = isSelected,
        _isDarkMode = isDarkMode,
        _onTap = onTap;

  final RequestDetails _request;
  final bool _isSelected;
  final bool _isDarkMode;
  final void Function(BuildContext context, RequestDetails request) _onTap;

  @override
  Widget build(BuildContext context) {
    Widget child = ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
      tileColor: InspectorHelper.specifyStatusCodeColor(_request.statusCode),
      leading: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            _request.requestMethod.name,
            style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          Text(
            _request.receivedTime != null
                ? InspectorHelper.calculateDuration(
                    _request.sentTime,
                    _request.receivedTime!,
                  )
                : InspectorHelper.extractTimeText(_request.sentTime),
            style: TextStyle(color: Colors.grey[800]),
          ),
        ],
      ),
      title: Text(_request.requestName),
      subtitle: Text(_request.url),
      trailing: Text(
        _request.statusCode?.toString() ?? 'Err',
        style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
      ),
      // Pass the current context and the request to the onTap callback
      onTap: () => _onTap(context, _request),
    );

    if (_isSelected) {
      child = DecoratedBox(
        decoration: BoxDecoration(
          border: _isDarkMode
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
