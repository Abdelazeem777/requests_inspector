import 'package:requests_inspector/src/enums/requests_methods.dart';
import 'package:requests_inspector/src/request_details.dart';
import 'package:requests_inspector/src/response_details.dart';

abstract class StopperFilter {
  bool shouldStop(dynamic details);
}

class RequestStopperFilter implements StopperFilter {
  const RequestStopperFilter({
    this.requestMethod,
    this.urlPattern,
  });

  final RequestMethod? requestMethod;
  final String? urlPattern;

  @override
  bool shouldStop(dynamic details) {
    if (details is! RequestDetails) return false;

    // If method filter is set, check it
    if (requestMethod != null && details.requestMethod != requestMethod) {
      return false;
    }

    // If URL filter is set, check it
    if (urlPattern != null &&
        urlPattern!.trim().isNotEmpty &&
        !details.url.toLowerCase().contains(urlPattern!.trim().toLowerCase())) {
      return false;
    }

    return true;
  }
}

class ResponseStopperFilter implements StopperFilter {
  const ResponseStopperFilter({
    this.statusCode,
    this.urlPattern,
  });

  final int? statusCode;
  final String? urlPattern;

  @override
  bool shouldStop(dynamic details) {
    if (details is! ResponseDetails) return false;

    // If status code filter is set, check it
    if (statusCode != null && details.statusCode != statusCode) {
      return false;
    }

    // If URL filter is set, check it
    if (urlPattern != null &&
        urlPattern!.trim().isNotEmpty &&
        !details.url.toLowerCase().contains(urlPattern!.trim().toLowerCase())) {
      return false;
    }

    return true;
  }
}
