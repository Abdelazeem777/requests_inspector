import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../requests_inspector.dart';
import '../jsonToDart/model_generator.dart';

class DartModelGeneratorWidget extends StatefulWidget {
  const DartModelGeneratorWidget({super.key});

  @override
  State<DartModelGeneratorWidget> createState() =>
      _DartModelGeneratorWidgetState();
}

class _DartModelGeneratorWidgetState extends State<DartModelGeneratorWidget> {
  String _generatedDartCode = '';
  bool _isGenerating = false;
  String _className = 'MyModel';
  final TextEditingController _classNameController = TextEditingController();
  RequestDetails? _lastSelectedRequest;

  @override
  void initState() {
    super.initState();
    _classNameController.text = _className;
  }

  @override
  void dispose() {
    _classNameController.dispose();
    super.dispose();
  }

  void _generateDartModel() {
    final selectedRequest = InspectorController().selectedRequest;
    if (selectedRequest == null) {
      setState(() {
        _generatedDartCode =
            'No request selected. Please select a request from the "All" tab first.';
      });
      return;
    }

    final responseBody = selectedRequest.responseBody;
    if (responseBody == null || responseBody.isEmpty) {
      setState(() {
        _generatedDartCode =
            'No response body available for the selected request.';
      });
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      // Convert responseBody to JSON string if it's not already
      String jsonString;
      if (responseBody is String) {
        jsonString = responseBody;
      } else {
        jsonString = jsonEncode(responseBody);
      }

      // Use the advanced ModelGenerator for proper nested object handling
      final modelGenerator = ModelGenerator(_className);
      final dartCode = modelGenerator.generateDartClasses(jsonString);

      setState(() {
        _generatedDartCode = dartCode.code;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _generatedDartCode = 'Error generating Dart model: $e';
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector<InspectorController, (bool, RequestDetails?)>(
      selector: (_, controller) =>
          (controller.isDarkMode, controller.selectedRequest),
      builder: (context, data, _) {
        final isDarkMode = data.$1;
        final selectedRequest = data.$2;

        // Reset generated code when a new request is selected
        if (_lastSelectedRequest != selectedRequest) {
          _lastSelectedRequest = selectedRequest;
          if (_generatedDartCode.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _generatedDartCode = '';
              });
            });
          }
        }
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Class name input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _classNameController,
                      decoration: InputDecoration(
                        labelText: 'Class Name',
                        border: const OutlineInputBorder(),
                        labelStyle: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      onChanged: (value) {
                        _className = value.isNotEmpty ? value : 'MyModel';
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isGenerating ? null : _generateDartModel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDarkMode ? Colors.grey[800] : Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: _isGenerating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Generate'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Generated code display
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                        border: Border.all(
                          color: isDarkMode
                              ? Colors.grey[700]!
                              : Colors.grey[300]!,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _generatedDartCode.isEmpty
                          ? selectedRequest != null
                              ? Text(
                                  'Selected Request:\n\n Request Name: ${selectedRequest.requestName}\n\n Request Method: ${selectedRequest.requestMethod.name}\n\n URL: ${selectedRequest.url}\n\nClick "Generate" to create a Dart model')
                              : Center(
                                  child: Text(
                                    'Select a request and click "Generate" to create a Dart model',
                                    style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white70
                                          : Colors.black54,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                          : SingleChildScrollView(
                              child: SelectableText(
                                _generatedDartCode,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 14,
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                    ),
                    if (_generatedDartCode.isNotEmpty)
                      PositionedDirectional(
                        end: 0,
                        child: IconButton(
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: _generatedDartCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                    'Dart model copied to clipboard!'),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.copy,
                            color: Colors.grey,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Copy button
            ],
          ),
        );
      },
    );
  }
}
