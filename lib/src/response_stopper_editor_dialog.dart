import 'package:flutter/material.dart';
import 'package:requests_inspector/src/json_pretty_converter.dart';

import 'shared_widgets/inspector_dialog_text_field.dart';

class ResponseStopperEditorDialog extends StatefulWidget {
  const ResponseStopperEditorDialog({super.key, required responseData})
      : _responseData = responseData;

  final _responseData;

  @override
  State<ResponseStopperEditorDialog> createState() =>
      _ResponseStopperEditorDialogState();
}

class _ResponseStopperEditorDialogState
    extends State<ResponseStopperEditorDialog> {
  late dynamic _newResponseData;

  @override
  void initState() {
    super.initState();
    _newResponseData = widget._responseData;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(primary: Colors.grey[800]!),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: AlertDialog(
          title: const Text(
            '🕵',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 32.0),
          ),
          contentPadding: EdgeInsets.zero,
          insetPadding: const EdgeInsets.all(16.0),
          backgroundColor: const Color.fromARGB(255, 34, 32, 32),
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildBody(context)),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(foregroundColor: Colors.white),
                    child: const Text('Receive'),
                    onPressed: () =>
                        Navigator.of(context).pop(_newResponseData),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final responseDataType = _newResponseData.runtimeType.toString();
    return Scrollbar(
      trackVisibility: true,
      thumbVisibility: true,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text('Response Body: '),
          const SizedBox(height: 4.0),
          InspectorDialogTextField(
            text: JsonPrettyConverter().convert(_newResponseData),
            onChanged: (value) => _newResponseData =
                JsonPrettyConverter().deconvertFrom(value, responseDataType),
          ),
          const SizedBox(height: 8.0),
        ],
      ),
    );
  }
}
