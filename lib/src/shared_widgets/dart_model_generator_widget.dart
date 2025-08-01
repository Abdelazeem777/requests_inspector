import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../requests_inspector.dart';

class DartModelGeneratorWidget extends StatefulWidget {
  const DartModelGeneratorWidget({super.key});

  @override
  State<DartModelGeneratorWidget> createState() => _DartModelGeneratorWidgetState();
}

class _DartModelGeneratorWidgetState extends State<DartModelGeneratorWidget> {
  String _generatedDartCode = '';
  bool _isGenerating = false;
  String _className = 'MyModel';
  final TextEditingController _classNameController = TextEditingController();

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
    print('selectedRequest: ${selectedRequest?.responseBody.runtimeType}');
    if (selectedRequest == null) {
      setState(() {
        _generatedDartCode = 'No request selected. Please select a request from the "All" tab first.';
      });
      return;
    }

    final responseBody = selectedRequest.responseBody;
    if (responseBody == null || responseBody.isEmpty) {
      setState(() {
        _generatedDartCode = 'No response body available for the selected request.';
      });
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      // Simple JSON to Dart model generation
      final dartCode = _generateSimpleDartModel(jsonEncode(responseBody), _className);
      setState(() {
        _generatedDartCode = dartCode;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _generatedDartCode = 'Error generating Dart model: $e';
        _isGenerating = false;
      });
    }
  }

  String _generateSimpleDartModel(String jsonString, String className) {
    try {
      // Parse JSON
      final dynamic jsonData = _parseJson(jsonString);
      if (jsonData == null) {
        return 'Invalid JSON format';
      }

      // Generate Dart class
      final buffer = StringBuffer();
      buffer.writeln('class $className {');

      if (jsonData is Map<String, dynamic>) {
        // Generate fields
        jsonData.forEach((key, value) {
          final fieldType = _getDartType(value);
          final fieldName = _toCamelCase(key);
          buffer.writeln('  final $fieldType $fieldName;');
        });

        buffer.writeln();

        // Generate constructor
        buffer.write('  $className({');
        final fields = jsonData.keys.map((key) => 'required this.${_toCamelCase(key)}').join(', ');
        buffer.writeln(fields);
        buffer.writeln('  });');

        buffer.writeln();

        // Generate fromJson method
        buffer.writeln('  factory $className.fromJson(Map<String, dynamic> json) {');
        buffer.writeln('    return $className(');
        jsonData.forEach((key, value) {
          final fieldName = _toCamelCase(key);
          buffer.writeln('      $fieldName: json[\'$key\'],');
        });
        buffer.writeln('    );');
        buffer.writeln('  }');

        buffer.writeln();

        // Generate toJson method
        buffer.writeln('  Map<String, dynamic> toJson() {');
        buffer.writeln('    return {');
        jsonData.forEach((key, value) {
          final fieldName = _toCamelCase(key);
          buffer.writeln('      \'$key\': $fieldName,');
        });
        buffer.writeln('    };');
        buffer.writeln('  }');
      } else {
        buffer.writeln('  // Note: Root JSON is not an object, consider using a different approach');
      }

      buffer.writeln('}');

      return buffer.toString();
    } catch (e) {
      return 'Error parsing JSON: $e';
    }
  }

  dynamic _parseJson(String jsonString) {
    try {
      return json.decode(jsonString);
    } catch (e) {
      // Try to parse as a simple JSON object
      try {
        final trimmed = jsonString.trim();
        if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
          return json.decode(trimmed);
        }
      } catch (e2) {
        // Ignore
      }
      rethrow;
    }
  }

  String _getDartType(dynamic value) {
    if (value == null) return 'dynamic';
    if (value is String) return 'String';
    if (value is int) return 'int';
    if (value is double) return 'double';
    if (value is bool) return 'bool';
    if (value is List) {
      if (value.isEmpty) return 'List<dynamic>';
      final firstType = _getDartType(value.first);
      return 'List<$firstType>';
    }
    if (value is Map) return 'Map<String, dynamic>';
    return 'dynamic';
  }

  String _toCamelCase(String text) {
    if (text.isEmpty) return text;

    // Handle snake_case to camelCase
    final words = text.split('_');
    if (words.length > 1) {
      final first = words.first.toLowerCase();
      final rest = words.skip(1).map((word) => 
        word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase()
      ).join('');
      return first + rest;
    }

    // Handle kebab-case to camelCase
    final kebabWords = text.split('-');
    if (kebabWords.length > 1) {
      final first = kebabWords.first.toLowerCase();
      final rest = kebabWords.skip(1).map((word) => 
        word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase()
      ).join('');
      return first + rest;
    }

    // Return as is for simple cases
    return text.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Selector<InspectorController, bool>(
      selector: (_, controller) => controller.isDarkMode,
      builder: (context, isDarkMode, _) {
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
                      backgroundColor: isDarkMode ? Colors.grey[800] : Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: _isGenerating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Generate'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Generated code display
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                    border: Border.all(
                      color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _generatedDartCode.isEmpty
                      ? Center(
                          child: Text(
                            'Select a request and click "Generate" to create a Dart model',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white70 : Colors.black54,
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
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                ),
              ),

              // Copy button
              if (_generatedDartCode.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _generatedDartCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Dart model copied to clipboard!'),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy to Clipboard'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
