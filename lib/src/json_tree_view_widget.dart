import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'shared_widgets/highlighted_text.dart';
import 'helpers/search_helper.dart';
import 'inspector_controller.dart';
import 'package:provider/provider.dart';

class JsonTreeView extends StatelessWidget {
  final dynamic data;
  final bool _isDarkMode;
  final String searchQuery;
  final int matchIndexOffset;

  const JsonTreeView(
    this.data, {
    super.key,
    required bool isDarkMode,
    this.searchQuery = '',
    this.matchIndexOffset = 0,
  }) : _isDarkMode = isDarkMode;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: _buildNode(context, data, currentOffset: matchIndexOffset),
      ),
    );
  }

  Widget _buildNode(BuildContext context, dynamic node,
      {String? keyName, required int currentOffset}) {
    if (node is Map<String, dynamic>) {
      return _buildMapNode(context, node, keyName, currentOffset);
    } else if (node is List) {
      return _buildListNode(context, node, keyName, currentOffset);
    } else if (node is FormData) {
      return _buildFormDataNode(context, node, keyName, currentOffset);
    } else {
      return _buildLeafNode(context, keyName, node, currentOffset);
    }
  }

  Widget _buildMapNode(
    BuildContext context,
    Map<String, dynamic> map,
    String? keyName,
    int currentOffset,
  ) {
    if (map.isEmpty) {
      return _buildLeafNode(context, keyName, '{}', currentOffset);
    }

    final children = <Widget>[];
    var offset = currentOffset;

    for (final entry in map.entries) {
      children.add(_buildNode(context, entry.value,
          keyName: entry.key, currentOffset: offset));
      offset += _countMatchesInNode(entry.value, entry.key);
    }

    children.add(_buildClosingBracket(context, '} ,'));

    final totalMatches = _countMatchesInNode(map, keyName);

    return _CustomExpansionTile(
      titleString: keyName != null ? '"$keyName" : ' : '',
      children: children,
      collapsedCount: map.length,
      isObject: true,
      initiallyExpanded: true,
      isDarkMode: _isDarkMode,
      matchIndexOffset: currentOffset,
      totalMatches: totalMatches,
    );
  }

  Widget _buildListNode(
      BuildContext context, List list, String? keyName, int currentOffset) {
    if (list.isEmpty) {
      return _buildLeafNode(context, keyName, '[]', currentOffset);
    }

    final children = <Widget>[];
    var offset = currentOffset;

    for (final item in list) {
      children.add(_buildNode(context, item, currentOffset: offset));
      offset += _countMatchesInNode(item, null);
    }

    children.add(_buildClosingBracket(context, '] ,'));

    final totalMatches = _countMatchesInNode(list, keyName);

    return _CustomExpansionTile(
      titleString: keyName != null ? '"$keyName" : ' : '',
      children: children,
      collapsedCount: list.length,
      isObject: false,
      initiallyExpanded: true,
      isDarkMode: _isDarkMode,
      matchIndexOffset: currentOffset,
      totalMatches: totalMatches,
    );
  }

  Widget _buildFormDataNode(
    BuildContext context,
    FormData formData,
    String? keyName,
    int currentOffset,
  ) {
    final length = formData.fields.length + formData.files.length;
    if (length == 0) {
      return _buildLeafNode(context, keyName, '{}', currentOffset);
    }

    final children = <Widget>[];
    var offset = currentOffset;

    for (final field in formData.fields) {
      children.add(_buildNode(context, field.value,
          keyName: field.key, currentOffset: offset));
      offset += _countMatchesInNode(field.value, field.key);
    }

    for (final file in formData.files) {
      final sizeInMb = file.value.length ~/ 1024;
      final fileSizeString = '${sizeInMb.toStringAsFixed(1)} kb';
      final nodeValue = "($fileSizeString) - ${file.value.filename}";
      children.add(_buildNode(context, nodeValue,
          keyName: file.key, currentOffset: offset));
      offset += _countMatchesInNode(nodeValue, file.key);
    }

    children.add(_buildClosingBracket(context, '} ,'));

    final totalMatches = _countMatchesInNode(formData, keyName);

    return _CustomExpansionTile(
      titleString: keyName != null ? '"$keyName" : ' : '',
      children: children,
      collapsedCount: length,
      isObject: true,
      initiallyExpanded: true,
      isDarkMode: _isDarkMode,
      matchIndexOffset: currentOffset,
      totalMatches: totalMatches,
    );
  }

  int _countMatchesInNode(dynamic node, String? key) {
    if (searchQuery.isEmpty) return 0;

    if (node is Map<String, dynamic>) {
      var count = 0;
      for (final entry in node.entries) {
        count += _countMatchesInNode(entry.value, entry.key);
      }
      return count;
    } else if (node is List) {
      var count = 0;
      for (final item in node) {
        count += _countMatchesInNode(item, null);
      }
      return count;
    } else if (node is FormData) {
      var count = 0;
      for (final field in node.fields) {
        count += _countMatchesInNode(field.value, field.key);
      }
      for (final file in node.files) {
        final sizeInMb = file.value.length ~/ 1024;
        final fileSizeString = '${sizeInMb.toStringAsFixed(1)} kb';
        final nodeValue = "($fileSizeString) - ${file.value.filename}";
        count += _countMatchesInNode(nodeValue, file.key);
      }
      return count;
    } else {
      final formattedValue = (node is String && node != '{}' && node != '[]')
          ? '"$node"'
          : '$node';
      final fullText =
          '${key != null ? '"$key" : ' : ''}$formattedValue${key != null ? ',' : ''}';
      return SearchHelper.findMatches(text: fullText, query: searchQuery)
          .length;
    }
  }

  Widget _buildLeafNode(
      BuildContext context, String? key, dynamic value, int currentOffset) {
    String formattedValue;
    Color valueColor;

    if (value is String && (value == '{}' || value == '[]')) {
      formattedValue = value;
      valueColor = _isDarkMode ? Colors.white : Colors.black87;
    } else if (value is String) {
      formattedValue = '"$value"';
      valueColor = _isDarkMode ? Colors.green.shade300 : Colors.green.shade700;
    } else if (value is num) {
      formattedValue = value.toString();
      valueColor = _isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700;
    } else if (value is bool) {
      formattedValue = value.toString();
      valueColor =
          _isDarkMode ? Colors.orange.shade300 : Colors.orange.shade700;
    } else if (value == null) {
      formattedValue = 'null';
      valueColor = _isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
    } else {
      formattedValue = value.toString();
      valueColor = _isDarkMode ? Colors.white : Colors.black87;
    }

    final spans = <TextSpan>[];
    if (key != null) {
      spans.add(TextSpan(
        text: '"$key" : ',
        style: TextStyle(
          fontSize: 14,
          color: _isDarkMode ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ));
    }

    spans.add(TextSpan(
      text: formattedValue,
      style: TextStyle(
        fontSize: 14,
        color: valueColor,
        fontWeight: FontWeight.w500,
      ),
    ));

    if (key != null) {
      spans.add(TextSpan(
        text: ',',
        style: TextStyle(
          fontSize: 14,
          color: _isDarkMode ? Colors.white : Colors.black87,
        ),
      ));
    }

    return Padding(
      padding: const EdgeInsets.only(left: 12.0),
      child: HighlightedText(
        spans: spans,
        searchQuery: searchQuery,
        isDarkMode: _isDarkMode,
        matchIndexOffset: currentOffset,
      ),
    );
  }

  Widget _buildClosingBracket(BuildContext context, String bracket) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      // Consistent with general indentation
      child: Text(
        bracket,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}

class _CustomExpansionTile extends StatefulWidget {
  final String? titleString;
  final List<Widget> children;
  final bool initiallyExpanded;
  final int? collapsedCount;
  final bool isObject;
  final bool isDarkMode;

  final int matchIndexOffset;
  final int totalMatches;

  const _CustomExpansionTile({
    required this.titleString,
    required this.children,
    this.initiallyExpanded = false,
    this.collapsedCount,
    this.isObject = false,
    required this.isDarkMode,
    this.matchIndexOffset = 0,
    this.totalMatches = 0,
  });

  @override
  State<_CustomExpansionTile> createState() => _CustomExpansionTileState();
}

class _CustomExpansionTileState extends State<_CustomExpansionTile>
    with SingleTickerProviderStateMixin {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor =
        widget.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;

    final bool hasTitleString =
        widget.titleString != null && widget.titleString!.isNotEmpty;

    return Selector<InspectorController, int>(
      selector: (_, controller) => controller.currentMatchIndex,
      builder: (context, currentMatchIndex, _) {
        final isActive = currentMatchIndex >= widget.matchIndexOffset &&
            currentMatchIndex < widget.matchIndexOffset + widget.totalMatches;

        if (isActive && !_expanded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _expanded = true;
              });
            }
          });
        }

        return Padding(
          padding: const EdgeInsets.only(left: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _expanded = !_expanded;
                  });
                },
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedRotation(
                        turns: _expanded ? 0.25 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.arrow_right,
                          size: 16,
                          color: secondaryTextColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        fit: FlexFit.loose,
                        child: Text.rich(
                          TextSpan(
                            children: [
                              if (hasTitleString)
                                TextSpan(
                                  text: widget.titleString,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                    color: textColor,
                                  ),
                                ),
                              if (_expanded)
                                TextSpan(
                                  text: widget.isObject ? '{' : '[',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                    color: textColor,
                                  ),
                                )
                              else
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: widget.isObject ? '{' : '[',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: textColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (widget.collapsedCount != null)
                                      TextSpan(
                                        text: widget.collapsedCount.toString(),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: secondaryTextColor,
                                        ),
                                      ),
                                    TextSpan(
                                      text: widget.isObject ? '} ,' : '] ,',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: textColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_expanded)
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: widget.children,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
