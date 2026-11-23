import 'dart:convert'; // for jsonEncode and Uri.encodeQueryComponent

import 'package:dio/dio.dart';

import 'request_details.dart';
import 'enums/requests_methods.dart'; // for File

class CurlCommandGenerator {
  final RequestDetails details;

  CurlCommandGenerator(this.details);

  String generate() {
    StringBuffer curlCommand = StringBuffer("curl ");

    // Adding Method Type
    _addMethodType(curlCommand);

    // Adding URL (with its query parameters)
    _addURL(curlCommand);

    // Adding Headers
    _addHeaders(curlCommand);

    // Adding Request Body
    _addRequestBody(curlCommand);

    // Additional Options
    _addAdditionalOptions(curlCommand);

    return curlCommand.toString();
  }

  void _addMethodType(StringBuffer curlCommand) {
    switch (details.requestMethod) {
      case RequestMethod.GET:
        curlCommand.write("-X GET ");
        break;
      case RequestMethod.POST:
        curlCommand.write("-X POST ");
        break;
      case RequestMethod.PATCH:
        curlCommand.write("-X PATCH ");
        break;
      case RequestMethod.PUT:
        curlCommand.write("-X PUT ");
        break;
      case RequestMethod.DELETE:
        curlCommand.write("-X DELETE ");
        break;
      case RequestMethod.HEAD:
        // With `-X HEAD`, curl waits for a response body that never comes.
        curlCommand.write("-I ");
        break;
      case RequestMethod.OPTIONS:
        curlCommand.write("-X OPTIONS ");
        break;
      default:
        throw Exception("Invalid Request Method");
    }
  }

  /// Quotes [value] as a single POSIX shell word: `'` becomes `'\''`.
  static String _quote(String value) => "'${value.replaceAll("'", r"'\''")}'";

  void _addURL(StringBuffer curlCommand) {
    curlCommand.write('${_quote('${details.url}${_queryString()}')} ');
  }

  void _addHeaders(StringBuffer curlCommand) {
    if (details.headers != null) {
      details.headers.forEach((key, value) {
        if (key == 'content-length') return;
        curlCommand.write('-H ${_quote('$key: $value')} ');
      });
    }
  }

  String _queryString() {
    if (details.queryParameters == null || details.queryParameters.isEmpty) {
      return '';
    }
    final params = <String>[];
    details.queryParameters.forEach((key, value) {
      params.add(
        "${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(value.toString())}",
      );
    });
    return '?${params.join('&')}';
  }

  // `--data-raw` and `--form-string` (unlike `-d` and `-F`) send a value that
  // starts with `@` as is, instead of reading the local file it names.
  void _addRequestBody(StringBuffer curlCommand) {
    // curl can't send a body with `-I` (HEAD).
    if (details.requestMethod == RequestMethod.HEAD) return;
    if (details.requestBody != null) {
      String contentType =
          details.headers?['content-type'] ??
          details.headers?['Content-Type'] ??
          '';
      if (contentType.contains('application/x-www-form-urlencoded')) {
        StringBuffer bodyBuffer = StringBuffer();
        (details.requestBody as Map).forEach((key, value) {
          bodyBuffer.write(
            "${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(value.toString())}&",
          );
        });
        String bodyString = bodyBuffer.toString();
        bodyString = bodyString.substring(
          0,
          bodyString.length - 1,
        ); // Remove last &
        curlCommand.write("--data-raw ${_quote(bodyString)} ");
      } else if (contentType.contains('multipart/form-data')) {
        if (details.requestBody is FormData) {
          FormData formData = details.requestBody as FormData;
          for (var mapEntry in formData.fields) {
            curlCommand.write(
              "--form-string ${_quote('${mapEntry.key}=${mapEntry.value}')} ",
            );
          }

          for (var file in formData.files) {
            String fileName = file.value.filename ?? 'file';
            curlCommand.write("-F ${_quote('${file.key}=@$fileName')} ");
          }
        }
      } else {
        final body = details.requestBody;
        final bodyString = body is String ? body : jsonEncode(body);
        curlCommand.write("--data-raw ${_quote(bodyString)} ");
      }
    }
  }

  void _addAdditionalOptions(StringBuffer curlCommand) {
    curlCommand
      ..write("-L ") // Follow Redirects
      ..write("-k "); // Insecure SSL
  }
}

// Usage:
// CurlCommandGenerator generator = CurlCommandGenerator(details);
// String curlCommand = generator.generate();
// print(curlCommand);
