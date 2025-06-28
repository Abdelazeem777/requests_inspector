import 'package:flutter/material.dart';

class JsonTreeView extends StatelessWidget {
  final dynamic data;
  final bool _isDarkMode;
  const JsonTreeView(this.data, {super.key, required bool isDarkMode})
      : _isDarkMode = isDarkMode;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: _buildNode(context, data),
      ),
    );
  }

  Widget _buildNode(BuildContext context, dynamic node, {String? keyName}) {
    Widget content;
    if (node is Map<String, dynamic>) {
      content = _buildMapNode(context, node, keyName);
    } else if (node is List) {
      content = _buildListNode(context, node, keyName);
    } else {
      content = _buildLeafNode(context, keyName, node);
    }

    return content;
  }

  Widget _buildMapNode(
      BuildContext context, Map<String, dynamic> map, String? keyName) {
    final isEmpty = map.isEmpty;

    if (isEmpty) {
      return _buildLeafNode(context, keyName, '{}');
    }

    return _CustomExpansionTile(
      titleString: keyName != null ? '"$keyName" : ' : '',
      children: [
        ...map.entries.map((e) {
          return _buildNode(context, e.value, keyName: e.key);
        }),
        _buildClosingBracket(context, '} ,'),
      ],
      collapsedCount: map.length,
      isObject: true,
      initiallyExpanded: true,
      isDarkMode: _isDarkMode,
    );
  }

  Widget _buildListNode(BuildContext context, List list, String? keyName) {
    final isEmpty = list.isEmpty;

    if (isEmpty) {
      return _buildLeafNode(context, keyName, '[]');
    }

    return _CustomExpansionTile(
      titleString: keyName != null ? '"$keyName" : ' : '',
      children: [
        ...list.asMap().entries.map((e) {
          return _buildNode(context, e.value, keyName: null);
        }),
        _buildClosingBracket(context, '] ,'),
      ],
      collapsedCount: list.length,
      isObject: false,
      initiallyExpanded: true,
      isDarkMode: _isDarkMode,
    );
  }

  Widget _buildLeafNode(BuildContext context, String? key, dynamic value) {
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

    return Padding(
      padding: const EdgeInsets.only(left: 12.0),
      child: SelectableText.rich(
        TextSpan(
          children: [
            if (key != null) ...[
              TextSpan(
                text: '"$key" : ',
                style: TextStyle(
                  fontSize: 14,
                  color: _isDarkMode ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            TextSpan(
              text: formattedValue,
              style: TextStyle(
                fontSize: 14,
                color: valueColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (key != null)
              TextSpan(
                text: ',',
                style: TextStyle(
                  fontSize: 14,
                  color: _isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
          ],
        ),
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
          color: _isDarkMode ? Colors.grey.shade400 : Colors.black87,
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

  const _CustomExpansionTile({
    required this.titleString,
    required this.children,
    this.initiallyExpanded = false,
    this.collapsedCount,
    this.isObject = false,
    required this.isDarkMode,
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
  }
}
