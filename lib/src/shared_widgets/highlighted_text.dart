import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:requests_inspector/src/inspector_controller.dart';
import 'package:requests_inspector/src/helpers/search_helper.dart';

class HighlightedText extends StatefulWidget {
  final String text;
  final String searchQuery;
  final TextStyle? style;
  final bool isDarkMode;
  final int matchIndexOffset;

  const HighlightedText({
    super.key,
    required this.text,
    required this.searchQuery,
    this.style,
    required this.isDarkMode,
    this.matchIndexOffset = 0,
  });

  @override
  State<HighlightedText> createState() => _HighlightedTextState();
}

class _HighlightedTextState extends State<HighlightedText> {
  final _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    if (widget.searchQuery.isEmpty) {
      return SelectableText(
        widget.text,
        style: widget.style,
        contextMenuBuilder: _buildContextMenu,
      );
    }

    final matches = SearchHelper.findMatches(
      text: widget.text,
      query: widget.searchQuery,
    );

    if (matches.isEmpty) {
      return SelectableText(
        widget.text,
        style: widget.style,
        contextMenuBuilder: _buildContextMenu,
      );
    }

    return Selector<InspectorController, int>(
      selector: (_, controller) => controller.currentMatchIndex,
      builder: (context, currentMatchIndex, _) {
        final spans = <TextSpan>[];
        var lastIndex = 0;

        for (var i = 0; i < matches.length; i++) {
          final match = matches[i];
          final globalMatchIndex = widget.matchIndexOffset + i;
          final isActive = globalMatchIndex == currentMatchIndex;

          if (match.start > lastIndex) {
            spans.add(TextSpan(
              text: widget.text.substring(lastIndex, match.start),
              style: widget.style,
            ));
          }

          spans.add(TextSpan(
            text: widget.text.substring(match.start, match.end),
            style: TextStyle(
              backgroundColor: isActive ? Colors.orange : Colors.yellow,
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: widget.style?.fontSize ?? 14,
            ),
          ));

          lastIndex = match.end;

          if (isActive) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Scrollable.ensureVisible(
                  _key.currentContext!,
                  alignment: 0.5,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            });
          }
        }

        if (lastIndex < widget.text.length) {
          spans.add(TextSpan(
            text: widget.text.substring(lastIndex),
            style: widget.style,
          ));
        }

        return SelectableText.rich(
          TextSpan(children: spans),
          key: _key,
          contextMenuBuilder: _buildContextMenu,
        );
      },
    );
  }

  Widget _buildContextMenu(
      BuildContext context, EditableTextState editableTextState) {
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: editableTextState.contextMenuAnchors,
      buttonItems: <ContextMenuButtonItem>[
        ContextMenuButtonItem(
          onPressed: () {
            editableTextState.copySelection(SelectionChangedCause.toolbar);
            editableTextState.hideToolbar();
          },
          type: ContextMenuButtonType.copy,
        ),
      ],
    );
  }
}
