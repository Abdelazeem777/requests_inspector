import 'dart:convert';

import 'package:dio/dio.dart';

/// Turns request/response data into text and back.
///
/// [convert] gives the text shown on the details page, in the shared log and
/// in the stopper editors. [deconvertFrom] turns the text edited in the
/// stopper editors back into data, so for JSON data
/// `deconvertFrom(convert(x), x.runtimeType.toString())` must give `x` back.
class JsonPrettyConverter {
  static JsonPrettyConverter? _instance;

  factory JsonPrettyConverter() =>
      _instance ??= JsonPrettyConverter._internal();

  JsonPrettyConverter._internal();

  late final JsonEncoder _encoder = JsonEncoder.withIndent(
    '  ',
    _toEncodableForDisplay,
  );

  /// Always returns a String: callers pass it straight to text widgets.
  String convert(text) {
    late final String prettyprint;

    if (text is Map || text is String || text is List)
      prettyprint = _encoder.convert(text);
    else if (text is FormData)
      prettyprint = 'FormData:\n${_convertToPrettyFromFormData(text)}';
    else if (text == null)
      prettyprint = '';
    else if (text is bool)
      prettyprint = text.toString();
    else if (text is num)
      prettyprint = text.toString();
    else
      prettyprint = text.toString();
    return prettyprint;
  }

  String _convertToPrettyFromFormData(FormData text) {
    final map = {
      for (final e in text.fields) e.key: e.value,
      for (final e in text.files) e.key: e.value.filename,
    };

    return _encoder.convert(map);
  }

  /// Called by [_encoder] only for values that have no JSON literal
  /// (DateTime, FormData, NaN, Maps with non-String keys, ...), at any depth.
  ///
  /// JSON values (null, bool, num, String, List, Map) never get here, so they
  /// keep their JSON types: `{"a": true}` is shown as `{"a": true}`, not
  /// `{"a": "true"}`, and decodes back to the same data.
  Object? _toEncodableForDisplay(Object? value) => value is Map
      ? {for (final e in value.entries) '${e.key}': e.value}
      : convert(value);

  /// Decodes [text] back into data of [oldDataType] (the `runtimeType` of the
  /// value [text] was converted from).
  ///
  /// Returns null when [text] can't be read as that type; the stopper editors
  /// then keep the previous value.
  dynamic deconvertFrom(String text, String? oldDataType) {
    if (oldDataType == null) return null;

    oldDataType = _removeUnderScoreIfExists(oldDataType);
    try {
      if (oldDataType.contains('Map')) return jsonDecode(text);
      if (oldDataType.startsWith('String')) return _decodeString(text);
      if (oldDataType.startsWith('List')) return jsonDecode(text);
      if (oldDataType == 'bool') return _decodeBool(text);
      if (oldDataType == 'int') return num.tryParse(text.trim());
      if (oldDataType == 'double') return num.tryParse(text.trim())?.toDouble();

      return null;
    } catch (e) {
      return null;
    }
  }

  /// [convert] shows a String as a JSON string literal (`"hello"`), so read
  /// it back the same way. Text that isn't a JSON string literal is kept
  /// verbatim.
  String _decodeString(String text) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is String) return decoded;
    } on FormatException {
      // Not a JSON string literal: fall through.
    }
    return text;
  }

  bool? _decodeBool(String text) {
    final trimmed = text.trim();
    if (trimmed == 'true') return true;
    if (trimmed == 'false') return false;
    return null;
  }

  String _removeUnderScoreIfExists(String dataTypeName) =>
      dataTypeName.replaceFirst('_', '');
}
