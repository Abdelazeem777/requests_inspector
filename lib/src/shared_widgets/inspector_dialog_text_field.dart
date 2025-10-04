import 'package:flutter/material.dart';

class InspectorDialogTextField extends StatelessWidget {
  const InspectorDialogTextField({
    super.key,
    required this.text,
    required this.onChanged,
  });

  final String text;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: const InputDecoration(
        filled: true,
        fillColor: Color.fromARGB(255, 19, 19, 19),
        border: OutlineInputBorder(borderSide: BorderSide.none),
      ),
      maxLines: null,
      minLines: 2,
      scrollPhysics: const NeverScrollableScrollPhysics(),
      controller: TextEditingController(text: text),
      onChanged: onChanged,
    );
  }
}
