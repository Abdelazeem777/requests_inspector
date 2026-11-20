import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:requests_inspector/src/inspector_controller.dart';
import 'package:requests_inspector/src/helpers/search_helper.dart';

class HighlightedText extends StatefulWidget {
  final String? text;
  final List<TextSpan>? spans;
  final String searchQuery;
  final TextStyle? style;
  final bool isDarkMode;
  final int matchIndexOffset;

  const HighlightedText({
    super.key,
    this.text,
    this.spans,
    required this.searchQuery,
    this.style,
    required this.isDarkMode,
    this.matchIndexOffset = 0,
  }) : assert(text != null || spans != null);

  @override
  State<HighlightedText> createState() => _HighlightedTextState();
}

class _HighlightedTextState extends State<HighlightedText> {
  final _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final effectiveText =
        widget.text ?? widget.spans?.map((s) => s.toPlainText()).join() ?? '';

    if (widget.searchQuery.isEmpty) {
      if (widget.spans != null) {
        return SelectableText.rich(
          TextSpan(children: widget.spans),
          contextMenuBuilder: _buildContextMenu,
        );
      }
      return SelectableText(
        effectiveText,
        style: widget.style,
        contextMenuBuilder: _buildContextMenu,
      );
    }

    final matches = SearchHelper.findMatches(
      text: effectiveText,
      query: widget.searchQuery,
    );

    if (matches.isEmpty) {
      if (widget.spans != null) {
        return SelectableText.rich(
          TextSpan(children: widget.spans),
          contextMenuBuilder: _buildContextMenu,
        );
      }
      return SelectableText(
        effectiveText,
        style: widget.style,
        contextMenuBuilder: _buildContextMenu,
      );
    }

    return Selector<InspectorController, int>(
      selector: (_, controller) => controller.currentMatchIndex,
      builder: (context, currentMatchIndex, _) {
        final finalSpans = <TextSpan>[];

        if (widget.spans != null) {
          var charOffset = 0;
          var matchIdx = 0;

          for (final originalSpan in widget.spans!) {
            final spanText = originalSpan.toPlainText();
            final spanStart = charOffset;
            final spanEnd = charOffset + spanText.length;

            var lastInternalIdx = 0;

            // Find matches that overlap with this span
            while (matchIdx < matches.length) {
              final match = matches[matchIdx];
              final globalMatchIndex = widget.matchIndexOffset + matchIdx;
              final isActive = globalMatchIndex == currentMatchIndex;

              if (match.end <= spanStart) {
                // This match ended before this span started
                matchIdx++;
                continue;
              }
              if (match.start >= spanEnd) {
                // This match (and all subsequent) starts after this span ends
                break;
              }

              // Overlap found
              final highlightStartInSpan =
                  (match.start - spanStart).clamp(0, spanText.length);
              final highlightEndInSpan =
                  (match.end - spanStart).clamp(0, spanText.length);

              // Add text before highlight within this span
              if (highlightStartInSpan > lastInternalIdx) {
                finalSpans.add(TextSpan(
                  text:
                      spanText.substring(lastInternalIdx, highlightStartInSpan),
                  style: originalSpan.style ?? widget.style,
                ));
              }

              // Add the highlighted portion
              finalSpans.add(TextSpan(
                text: spanText.substring(
                    highlightStartInSpan, highlightEndInSpan),
                style: (originalSpan.style ?? widget.style ?? const TextStyle())
                    .copyWith(
                  backgroundColor: isActive ? Colors.orange : Colors.yellow,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ));

              lastInternalIdx = highlightEndInSpan;

              if (isActive) {
                _triggerScroll();
              }

              if (match.end <= spanEnd) {
                // Finished with this match for this span, but maybe more matches in this span?
                matchIdx++;
              } else {
                // Match extends beyond this span, don't increment matchIdx yet
                break;
              }
            }

            // Add remaining text in span
            if (lastInternalIdx < spanText.length) {
              finalSpans.add(TextSpan(
                text: spanText.substring(lastInternalIdx),
                style: originalSpan.style ?? widget.style,
              ));
            }

            charOffset += spanText.length;
          }
        } else {
          var lastIndex = 0;
          for (var i = 0; i < matches.length; i++) {
            final match = matches[i];
            final globalMatchIndex = widget.matchIndexOffset + i;
            final isActive = globalMatchIndex == currentMatchIndex;

            if (match.start > lastIndex) {
              finalSpans.add(TextSpan(
                text: effectiveText.substring(lastIndex, match.start),
                style: widget.style,
              ));
            }

            finalSpans.add(TextSpan(
              text: effectiveText.substring(match.start, match.end),
              style: (widget.style ?? const TextStyle()).copyWith(
                backgroundColor: isActive ? Colors.orange : Colors.yellow,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ));

            lastIndex = match.end;

            if (isActive) {
              _triggerScroll();
            }
          }

          if (lastIndex < effectiveText.length) {
            finalSpans.add(TextSpan(
              text: effectiveText.substring(lastIndex),
              style: widget.style,
            ));
          }
        }

        return SelectableText.rich(
          TextSpan(children: finalSpans),
          key: _key,
          contextMenuBuilder: _buildContextMenu,
        );
      },
    );
  }

  void _triggerScroll() {
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
