import 'package:flutter/material.dart';
import 'package:requests_inspector/src/helpers/search_helper.dart';

class HighlightedText extends StatelessWidget {
  final String text;
  final String searchQuery;
  final TextStyle? style;
  final bool isDarkMode;

  const HighlightedText({
    super.key,
    required this.text,
    required this.searchQuery,
    this.style,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    
    if (searchQuery.isEmpty) {
      return SelectableText(
        text,
        style: style,
        contextMenuBuilder: (context, editableTextState) {
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
        },
      );
    }

    final matches = SearchHelper.findMatches(
      text: text,
      query: searchQuery,
    );


    if (matches.isEmpty) {
      return SelectableText(
        text,
        style: style,
        contextMenuBuilder: (context, editableTextState) {
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
        },
      );
    }

    final spans = <TextSpan>[];
    var lastIndex = 0;

    for (var i = 0; i < matches.length; i++) {
      final match = matches[i];

      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: style,
        ));
      }

      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: TextStyle(
          backgroundColor: Colors.yellow,
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: style?.fontSize ?? 14,
        ),
      ));

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: style,
      ));
    }

    return SelectableText.rich(
      TextSpan(children: spans),
      contextMenuBuilder: (context, editableTextState) {
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
      },
    );
  }
}

