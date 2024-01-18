import 'package:flutter/material.dart';
import 'package:requests_inspector/src/json_pretty_converter.dart';

import '../requests_inspector.dart';

class RequestEditorDialog extends StatefulWidget {
  const RequestEditorDialog({super.key, RequestDetails? requestDetails})
      : _requestDetails = requestDetails;

  final RequestDetails? _requestDetails;

  @override
  State<RequestEditorDialog> createState() => _RequestEditorDialogState();
}

class _RequestEditorDialogState extends State<RequestEditorDialog> {
  RequestDetails? _newRequestDetails;

  @override
  void initState() {
    super.initState();
    _newRequestDetails = widget._requestDetails;
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
                    child: const Text('Send'),
                    onPressed: () =>
                        Navigator.of(context).pop(_newRequestDetails),
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
    return Scrollbar(
      trackVisibility: true,
      thumbVisibility: true,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(16.0),
        children: [
          Row(
            children: [
              const Text('Request Method: '),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.0),
                  color: const Color.fromARGB(255, 19, 19, 19),
                ),
                child: DropdownButton<RequestMethod>(
                  dropdownColor: const Color.fromARGB(255, 19, 19, 19),
                  value: _newRequestDetails?.requestMethod,
                  underline: const SizedBox(),
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  onChanged: (value) => setState(() {
                    _newRequestDetails =
                        _newRequestDetails?.copyWith(requestMethod: value);
                  }),
                  items: RequestMethod.values
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.name),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
          const Text('URL: '),
          const SizedBox(height: 4.0),
          _InspectorDialogTextField(
            text: _newRequestDetails?.url ?? '',
            onChanged: (value) =>
                _newRequestDetails = _newRequestDetails?.copyWith(url: value),
          ),
          const SizedBox(height: 16.0),
          const Text('Headers: '),
          const SizedBox(height: 4.0),
          _InspectorDialogTextField(
            text: JsonPrettyConverter().convert(_newRequestDetails?.headers),
            onChanged: (value) => _newRequestDetails = _newRequestDetails
                ?.copyWith(headers: JsonPrettyConverter().mapFromString(value)),
          ),
          const SizedBox(height: 16.0),
          const Text('Query Parameters: '),
          const SizedBox(height: 4.0),
          _InspectorDialogTextField(
            text: JsonPrettyConverter()
                .convert(_newRequestDetails?.queryParameters),
            onChanged: (value) => _newRequestDetails =
                _newRequestDetails?.copyWith(
                    queryParameters:
                        JsonPrettyConverter().mapFromString(value)),
          ),
          const SizedBox(height: 16.0),
          const Text('Request Body: '),
          const SizedBox(height: 4.0),
          _InspectorDialogTextField(
            text:
                JsonPrettyConverter().convert(_newRequestDetails?.requestBody),
            onChanged: (value) => _newRequestDetails =
                _newRequestDetails?.copyWith(
                    requestBody: JsonPrettyConverter().mapFromString(value)),
          ),
          const SizedBox(height: 8.0),
        ],
      ),
    );
  }
}

class _InspectorDialogTextField extends StatelessWidget {
  const _InspectorDialogTextField({
    Key? key,
    required this.text,
    required this.onChanged,
  }) : super(key: key);

  final String text;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: const InputDecoration(
        filled: true,
        fillColor: Color.fromARGB(255, 19, 19, 19),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
        ),
      ),
      maxLines: null,
      minLines: 2,
      scrollPhysics: const NeverScrollableScrollPhysics(),
      controller: TextEditingController(text: text),
      onChanged: onChanged,
    );
  }
}
