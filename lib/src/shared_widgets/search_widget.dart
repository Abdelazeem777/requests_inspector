import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:requests_inspector/src/inspector_controller.dart';

class SearchWidget extends StatefulWidget {
  final bool isDarkMode;

  const SearchWidget({super.key, required this.isDarkMode});

  @override
  State<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _focusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();

      final controller = InspectorController();
      controller.addListener(_onControllerChanged);
    });
  }

  void _onControllerChanged() {
    if (!InspectorController().isSearchVisible &&
        _textController.text.isNotEmpty) {
      _textController.clear();
    }
  }

  @override
  void dispose() {
    InspectorController().removeListener(_onControllerChanged);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fillColor = widget.isDarkMode ? Colors.black : Colors.white;
    final iconColor = widget.isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return Selector<InspectorController, bool>(
      selector: (_, controller) => controller.isSearchVisible,
      builder: (context, isVisible, _) {
        if (!isVisible) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
          child: TextField(
            controller: _textController,
            focusNode: _focusNode,
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: 'Search...',
              fillColor: fillColor,
              filled: true,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Selector<InspectorController, InspectorController>(
                    selector: (_, controller) => controller,
                    builder: (context, controller, _) {
                      final current = controller.currentMatchIndex;
                      final total = controller.totalMatches;
                      if (total <= 0) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text(
                          '${current + 1} / $total',
                          style: TextStyle(
                            color: iconColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.keyboard_arrow_up,
                        size: 20, color: iconColor),
                    onPressed: InspectorController().previousMatch,
                    tooltip: 'Previous match',
                  ),
                  IconButton(
                    icon: Icon(Icons.keyboard_arrow_down,
                        size: 20, color: iconColor),
                    onPressed: InspectorController().nextMatch,
                    tooltip: 'Next match',
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 20, color: iconColor),
                    onPressed: () {
                      InspectorController().toggleSearchVisibility();
                    },
                    tooltip: 'Close',
                  ),
                ],
              ),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (value) {
              InspectorController().updateSearchQuery(value);
            },
            onSubmitted: (_) {
              final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
              if (isShiftPressed) {
                InspectorController().previousMatch();
              } else {
                InspectorController().nextMatch();
              }
              _focusNode.requestFocus();
            },
          ),
        );
      },
    );
  }
}
