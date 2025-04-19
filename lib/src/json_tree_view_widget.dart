import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../requests_inspector.dart';

class JsonTreeView extends StatelessWidget {
  final dynamic data;

  const JsonTreeView(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    return _buildNode(context, data);
  }

  Widget _buildNode(BuildContext context, dynamic node, {String? keyName}) {
    if (node is Map<String, dynamic>) {
      return _buildMapNode(context, node, keyName);
    } else if (node is List) {
      return _buildListNode(context, node, keyName);
    } else {
      return _buildLeafNode(context, keyName, node);
    }
  }

  Widget _buildMapNode(BuildContext context, Map<String, dynamic> map, String? keyName) {
    return _buildExpandableTile(
      title: keyName != null ? '"$keyName": {' : '{',
      children: map.entries.map((e) {
        return _buildNode(context, e.value, keyName: e.key);
      }).toList(),
      closing: '}',
    );
  }

  Widget _buildListNode(BuildContext context, List list, String? keyName) {
    return _buildExpandableTile(
      title: keyName != null ? '"$keyName": [' : '[',
      children: list.asMap().entries.map((e) {
        return _buildNode(context, e.value, keyName: '[${e.key}]');
      }).toList(),
      closing: ']',
    );
  }

  Widget _buildLeafNode(BuildContext context, String? key, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(left: 50.0, top: 2, bottom: 2),
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
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: _CustomExpansionTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          ...children,
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 2),
            child: Text(
              closing,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          )
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
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: AnimatedRotation(
            turns: _expanded ? 0.25 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.arrow_right),
          ),
          title: widget.title,
          onTap: () {
            setState(() {
              _expanded = !_expanded;
            });
          },
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.children,
            ),
          )
      ],
    );
  }
}
