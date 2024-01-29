import 'dart:convert'; // for jsonEncode and Uri.encodeQueryComponent

import 'package:dio/dio.dart';

import 'request_details.dart';
import 'requests_methods.dart'; // for File

class CurlCommandGenerator {
  final RequestDetails details;

  CurlCommandGenerator(this.details);

  String generate() {
    StringBuffer curlCommand = StringBuffer("curl -X ");

    // Adding Method Type
    _addMethodType(curlCommand);

    // Adding URL
    _addURL(curlCommand);

    // Adding Query Parameters
    _addQueryParameters(curlCommand);

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
        curlCommand.write("GET ");
        break;
      case RequestMethod.POST:
        curlCommand.write("POST ");
        break;
      case RequestMethod.PATCH:
        curlCommand.write("PATCH ");
        break;
      case RequestMethod.PUT:
        curlCommand.write("PUT ");
        break;
      case RequestMethod.DELETE:
        curlCommand.write("DELETE ");
        break;
      default:
        throw Exception("Invalid Request Method");
    }
  }

  void _addURL(StringBuffer curlCommand) {
    curlCommand.write('"${details.url}');
  }

  void _addHeaders(StringBuffer curlCommand) {
    if (details.headers != null) {
      details.headers.forEach((key, value) {
        if (key == 'content-length') return;
        curlCommand.write('-H "$key: $value" ');
      });
    }
  }

  void _addQueryParameters(StringBuffer curlCommand) {
    if (details.queryParameters != null && details.queryParameters.isNotEmpty) {
      StringBuffer paramString = StringBuffer("?");
      details.queryParameters.forEach((key, value) {
        paramString.write(
            "${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(value.toString())}&");
      });
      String paramStringFinal = paramString.toString();
      paramStringFinal = paramStringFinal.substring(
          0, paramStringFinal.length - 1); // remove last &
      curlCommand.write(paramStringFinal);
    }

    curlCommand.write('" ');
  }

  void _addRequestBody(StringBuffer curlCommand) {
    if (details.requestBody != null) {
      String contentType = details.headers?['content-type'] ??
          details.headers?['Content-Type'] ??
          '';
      if (contentType.contains('application/x-www-form-urlencoded')) {
        StringBuffer bodyBuffer = StringBuffer();
        (details.requestBody as Map).forEach((key, value) {
          bodyBuffer.write(
              "${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(value.toString())}&");
        });
        String bodyString = bodyBuffer.toString();
        bodyString =
            bodyString.substring(0, bodyString.length - 1); // Remove last &
        curlCommand.write("-d '$bodyString' ");
      } else if (contentType.contains('multipart/form-data')) {
        if (details.requestBody is FormData) {
          FormData formData = details.requestBody as FormData;
          for (var mapEntry in formData.fields) {
            curlCommand.write("-F '${mapEntry.key}=${mapEntry.value}' ");
          }

          for (var file in formData.files) {
            String fileName = file.value.filename ?? 'file';
            curlCommand.write("-F '${file.key}=@$fileName' ");
          }
        }
      } else {
        curlCommand.write("-d '${jsonEncode(details.requestBody)}' ");
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
