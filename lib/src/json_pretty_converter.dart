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
      prettyprint = _encoder.convert(text);
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
    return _encoder.convert(map);
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
