import 'package:flutter/material.dart';
import 'package:requests_inspector/src/enums/requests_methods.dart';
import 'package:requests_inspector/src/inspector_controller.dart';

class StopperFiltersDialog extends StatefulWidget {
  const StopperFiltersDialog({
    super.key,
    required this.isDarkMode,
    required this.stopperType,
  });

  final bool isDarkMode;
  final StopperType stopperType;

  @override
  State<StopperFiltersDialog> createState() => _StopperFiltersDialogState();
}

enum StopperType { request, response }

class _StopperFiltersDialogState extends State<StopperFiltersDialog> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _statusCodeController = TextEditingController();
  RequestMethod? _selectedMethod;

  @override
  void initState() {
    super.initState();
    final controller = InspectorController();
    if (widget.stopperType == StopperType.request) {
      _selectedMethod = controller.requestStopperFilterMethod;
      _urlController.text = controller.requestStopperFilterUrl ?? '';
    } else {
      _statusCodeController.text =
          controller.responseStopperFilterStatusCode?.toString() ?? '';
      _urlController.text = controller.responseStopperFilterUrl ?? '';
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _statusCodeController.dispose();
    super.dispose();
  }

  ButtonStyle _getButtonStyle(bool isPrimary) {
    return ElevatedButton.styleFrom(
      backgroundColor: isPrimary
          ? (widget.isDarkMode ? Colors.grey[600] : Colors.grey[300])
          : (widget.isDarkMode ? Colors.grey[700] : Colors.grey[400]),
      foregroundColor: widget.isDarkMode ? Colors.white : Colors.black87,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.stopperType == StopperType.request
        ? 'Request Stopper Filters'
        : 'Response Stopper Filters';

    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.stopperType == StopperType.request)
              DropdownButtonFormField<RequestMethod?>(
                decoration: const InputDecoration(
                  labelText: 'Request Method',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                value: _selectedMethod,
                items: [
                  const DropdownMenuItem<RequestMethod?>(
                    value: null,
                    child: Text('Any'),
                  ),
                  ...RequestMethod.values.map(
                    (m) => DropdownMenuItem<RequestMethod?>(
                      value: m,
                      child: Text(m.name),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedMethod = value;
                  });
                },
              ),
            if (widget.stopperType == StopperType.request)
              const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL contains',
                hintText: 'e.g. /api/users',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            if (widget.stopperType == StopperType.response)
              const SizedBox(height: 12),
            if (widget.stopperType == StopperType.response)
              TextField(
                controller: _statusCodeController,
                decoration: const InputDecoration(
                  labelText: 'Status code',
                  hintText: 'e.g. 200',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
              ),
          ],
        ),
      ),
      actions: [
        ElevatedButton.icon(
          style: _getButtonStyle(false),
          icon: const Icon(Icons.clear_all),
          label: const Text('Clear'),
          onPressed: () {
            setState(() {
              _selectedMethod = null;
              _urlController.clear();
              _statusCodeController.clear();
            });
            final c = InspectorController();
            if (widget.stopperType == StopperType.request) {
              c.clearRequestStopperFilters();
            } else {
              c.clearResponseStopperFilters();
            }
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton.icon(
          style: _getButtonStyle(true),
          icon: const Icon(Icons.check),
          label: const Text('Apply'),
          onPressed: () {
            final c = InspectorController();
            if (widget.stopperType == StopperType.request) {
              c.setRequestStopperFilterMethod(_selectedMethod);
              c.setRequestStopperFilterUrl(_urlController.text);
              c.requestStopperEnabled = true;
            } else {
              c.setResponseStopperFilterUrl(_urlController.text);
              int? status;
              if (_statusCodeController.text.trim().isNotEmpty) {
                status = int.tryParse(_statusCodeController.text.trim());
              }
              c.setResponseStopperFilterStatusCode(status);
              c.responseStopperEnabled = true;
            }
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
