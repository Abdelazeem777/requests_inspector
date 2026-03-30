import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:requests_inspector/src/enums/requests_methods.dart';
import 'package:requests_inspector/src/inspector_controller.dart';

class FiltersDialog extends StatefulWidget {
  const FiltersDialog({super.key, required this.isDarkMode});

  final bool isDarkMode;

  @override
  State<FiltersDialog> createState() => _FiltersDialogState();
}

class _FiltersDialogState extends State<FiltersDialog> {
  final TextEditingController _statusCodeController = TextEditingController();
  RequestMethod? _selectedMethod;

  @override
  void initState() {
    super.initState();
    final controller = InspectorController();
    _selectedMethod = controller.filterRequestMethod;
    _statusCodeController.text = controller.filterStatusCode?.toString() ?? '';
  }

  @override
  void dispose() {
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
    return AlertDialog(
      title: const Text('Filter requests'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            const SizedBox(height: 12),
            TextField(
              controller: _statusCodeController,
              decoration: const InputDecoration(
                labelText: 'Status code',
                hintText: 'e.g. 200',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
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
              _statusCodeController.clear();
            });
            final c = InspectorController();
            c.clearFilters();
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton.icon(
          style: _getButtonStyle(true),
          icon: const Icon(Icons.check),
          label: const Text('Apply'),
          onPressed: () {
            final c = InspectorController();
            c.setRequestMethodFilter(_selectedMethod);
            int? status;
            if (_statusCodeController.text.trim().isNotEmpty) {
              status = int.tryParse(_statusCodeController.text.trim());
            }
            c.setStatusCodeFilter(status);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
