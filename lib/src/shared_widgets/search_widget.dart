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
    final backgroundColor =
        widget.isDarkMode ? Colors.grey[850] : Colors.grey[200];
    final borderColor = widget.isDarkMode ? Colors.grey[700] : Colors.grey[400];
    final textColor = widget.isDarkMode ? Colors.white : Colors.black87;
    final iconColor = widget.isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return Selector<InspectorController, bool>(
      selector: (_, controller) => controller.isSearchVisible,
      builder: (context, isVisible, _) {
        if (!isVisible) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.all(4.0),
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(4.0),
            border: Border.all(color: borderColor!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 180,
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  style: TextStyle(color: textColor, fontSize: 14),
                  cursorColor: textColor,
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: TextStyle(color: iconColor, fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 6.0,
                      vertical: 6.0,
                    ),
                  ),
                  onChanged: (value) {
                    InspectorController().updateSearchQuery(value);
                  },
                  onSubmitted: (_) {
                    final isShiftPressed =
                        HardwareKeyboard.instance.isShiftPressed;
                    if (isShiftPressed) {
                      InspectorController().previousMatch();
                    } else {
                      InspectorController().nextMatch();
                    }
                    _focusNode.requestFocus();
                  },
                ),
              ),
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
                icon: Icon(Icons.keyboard_arrow_up, size: 18, color: iconColor),
                onPressed: InspectorController().previousMatch,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ),
                tooltip: 'Previous match',
              ),
              IconButton(
                icon:
                    Icon(Icons.keyboard_arrow_down, size: 18, color: iconColor),
                onPressed: InspectorController().nextMatch,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ),
                tooltip: 'Next match',
              ),
              IconButton(
                icon: Icon(Icons.close, size: 16, color: iconColor),
                onPressed: () {
                  InspectorController().toggleSearchVisibility();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ),
                tooltip: 'Close',
              ),
            ],
          ),
        );
      },
    );
  }
}
