import 'package:flutter/material.dart';

class InspectorDialogTextField extends StatefulWidget {
  const InspectorDialogTextField({
    super.key,
    required this.text,
    required this.onChanged,
  });

  final String text;
  final ValueChanged<String> onChanged;

  @override
  State<InspectorDialogTextField> createState() =>
      _InspectorDialogTextFieldState();
}

class _InspectorDialogTextFieldState extends State<InspectorDialogTextField> {
  // Kept across rebuilds (e.g. when the keyboard opens), so the text being
  // edited and the cursor stay where they are.
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.text);
  }

  @override
  void didUpdateWidget(InspectorDialogTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only a new text from outside replaces what the user typed.
    if (widget.text != oldWidget.text && widget.text != _controller.text) {
      _controller.text = widget.text;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
      controller: _controller,
      onChanged: widget.onChanged,
    );
  }
}
