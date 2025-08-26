import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:requests_inspector/src/json_pretty_converter.dart';
import 'response_details.dart';

import 'shared_widgets/inspector_dialog_text_field.dart';

class ResponseStopperEditorDialog extends StatefulWidget {
  const ResponseStopperEditorDialog({
    super.key,
    required this.responseDetails,
  });

  final ResponseDetails responseDetails;

  @override
  State<ResponseStopperEditorDialog> createState() =>
      _ResponseStopperEditorDialogState();
}

class _ResponseStopperEditorDialogState
    extends State<ResponseStopperEditorDialog> {
  late ResponseDetails _newResponseDetails;

  @override
  void initState() {
    super.initState();
    _newResponseDetails = widget.responseDetails.copyWith();
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
                        Navigator.of(context).pop(_newResponseDetails),
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
    final responseDataType =
        _newResponseDetails.responseBody.runtimeType.toString();
    return Scrollbar(
      trackVisibility: true,
      thumbVisibility: true,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildStatusCodeField(),
          const SizedBox(height: 16.0),
          _buildResponseBodyField(responseDataType),
          const SizedBox(height: 16.0),
          _buildHeadersField(),
          const SizedBox(height: 8.0),
        ],
      ),
    );
  }

  Widget _buildStatusCodeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Status Code: '),
        const SizedBox(height: 4.0),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4.0),
            color: const Color.fromARGB(255, 19, 19, 19),
            border: Border.all(color: Colors.grey[600]!),
          ),
          child: TextFormField(
            initialValue: _newResponseDetails.statusCode.toString(),
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              hintText: '200',
              hintStyle: TextStyle(color: Colors.grey),
            ),
            onChanged: (value) {
              final statusCode = int.tryParse(value) ?? 200;
              _newResponseDetails =
                  _newResponseDetails.copyWith(statusCode: statusCode);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeadersField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Response Headers: '),
        const SizedBox(height: 4.0),
        InspectorDialogTextField(
          text: JsonPrettyConverter().convert(_newResponseDetails.headers),
          onChanged: (value) =>
              _newResponseDetails = _newResponseDetails.copyWith(
            headers: JsonPrettyConverter().deconvertFrom(
              value,
              _newResponseDetails.headers.runtimeType.toString(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResponseBodyField(String responseDataType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Response Body: '),
        const SizedBox(height: 4.0),
        InspectorDialogTextField(
          text: JsonPrettyConverter().convert(_newResponseDetails.responseBody),
          onChanged: (value) =>
              _newResponseDetails = _newResponseDetails.copyWith(
            responseBody:
                JsonPrettyConverter().deconvertFrom(value, responseDataType),
          ),
        ),
      ],
    );
  }
}
