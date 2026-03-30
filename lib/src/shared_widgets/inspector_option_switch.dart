import 'package:flutter/material.dart';

class InspectorOptionSwitch extends StatelessWidget {
  const InspectorOptionSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final void Function(bool)? onChanged;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      activeColor: Colors.green,
      activeTrackColor: Colors.grey[700],
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: Colors.grey[700],
      onChanged: onChanged,
    );
  }
}
