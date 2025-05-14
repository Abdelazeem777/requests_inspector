import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../requests_inspector.dart';

class JsonTreeView extends StatelessWidget {
  final dynamic data;

  const JsonTreeView(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: _buildNode(context, data, depth: 0),
    );
  }

  Widget _buildNode(BuildContext context, dynamic node, {String? keyName, required int depth}) {
    if (node is Map<String, dynamic>) {
      return _buildMapNode(context, node, keyName, depth);
    } else if (node is List) {
      return _buildListNode(context, node, keyName, depth);
    } else {
      return _buildLeafNode(context, keyName, node, depth);
    }
  }

  Widget _buildMapNode(BuildContext context, Map<String, dynamic> map, String? keyName, int depth) {
    return _buildExpandableTile(
      title: keyName != null ? '"$keyName": {' : '{',
      children: map.entries.map((e) {
        return _buildNode(context, e.value, keyName: e.key, depth: depth + 1);
      }).toList(),
      closing: '}',
      depth: depth,
    );
  }

  Widget _buildListNode(BuildContext context, List list, String? keyName, int depth) {
    return _buildExpandableTile(
      title: keyName != null ? '"$keyName": [' : '[',
      children: list.asMap().entries.map((e) {
        return _buildNode(context, e.value, keyName: '[${e.key}]', depth: depth + 1);
      }).toList(),
      closing: ']',
      depth: depth,
    );
  }

  Widget _buildLeafNode(BuildContext context, String? key, dynamic value, int depth) {
    return Padding(
      padding: EdgeInsets.only(left: depth * 16.0, top: 2, bottom: 2),
      child: SelectableText(
        "\"$key\": ${value is String ? "\"$value\"" : "$value"},",
        style: TextStyle(
          fontSize: 14,
          color: context.read<InspectorController>().isDarkMode
              ? Colors.white
              : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildExpandableTile({
    required String title,
    required List<Widget> children,
    required String closing,
    required int depth,
  }) {
    return Padding(
      padding: EdgeInsets.only(left: depth * 16.0),
      child: _CustomExpansionTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          ...children,
          // تعديل مكان قوس الإغلاق بدون padding إضافي
          Text(
            closing,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

}

class _CustomExpansionTile extends StatefulWidget {
  final Widget title;
  final List<Widget> children;

  const _CustomExpansionTile({
    required this.title,
    required this.children,
  });

  @override
  State<_CustomExpansionTile> createState() => _CustomExpansionTileState();
}

class _CustomExpansionTileState extends State<_CustomExpansionTile>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _expanded = !_expanded;
            });
          },
          child: Row(
            children: [
              AnimatedRotation(
                turns: _expanded ? 0.25 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.arrow_right),
              ),
              Expanded(child: widget.title),
            ],
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.children,
            ),
          ),
      ],
    );
  }
}
