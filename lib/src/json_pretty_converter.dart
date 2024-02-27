import 'dart:convert';

import 'package:dio/dio.dart';

class JsonPrettyConverter {
  static JsonPrettyConverter? _instance;

  factory JsonPrettyConverter() =>
      _instance ??= JsonPrettyConverter._internal();
  JsonPrettyConverter._internal() {
    _encoder = const JsonEncoder.withIndent('  ');
  }

  static late final JsonEncoder _encoder;

  String convert(text) {
    late final String prettyprint;
    if (text is Map || text is String || text is List)
      prettyprint = _convertToPrettyJsonFromMapOrJson(text);
    else if (text is FormData)
      prettyprint = 'FormData:\n${_convertToPrettyFromFormData(text)}';
    else if (text == null)
      prettyprint = '';
    else
      prettyprint = text.toString();
    return prettyprint;
  }

  String _convertToPrettyFromFormData(FormData text) {
    final map = {
      for (final e in text.fields) e.key: e.value,
      for (final e in text.files) e.key: e.value.filename
    };

    return _convertToPrettyJsonFromMapOrJson(map);
  }

  String _convertToPrettyJsonFromMapOrJson(text) {
    if (text is! Map) return _encoder.convert(text);

    text = {
      for (final e in text.entries)
        if (e.value is Map || e.value is List || e.value is String)
          e.key: e.value
        else
          e.key: convert(e.value)
    };
    return _encoder.convert(text);
  }

  dynamic deconvertFrom(String text, String? oldDataType) {
    if (oldDataType == null) return null;

    oldDataType = _removeUnderScoreIfExists(oldDataType);
    try {
      if (oldDataType.contains('Map')) return jsonDecode(text);
      if (oldDataType.startsWith('String')) return text;
      if (oldDataType.startsWith('List')) return jsonDecode(text);

      return null;
    } catch (e) {
      return null;
    }
  }

  String _removeUnderScoreIfExists(String dataTypeName) =>
      dataTypeName.replaceFirst('_', '');
}
