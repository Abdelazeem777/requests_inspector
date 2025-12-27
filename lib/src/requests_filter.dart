import 'package:requests_inspector/src/enums/requests_methods.dart';
import 'package:requests_inspector/src/request_details.dart';

abstract class RequestFilter {
  bool Function(RequestDetails requestDetails) get requestFilter;
}

class RequestMethodFilter implements RequestFilter {
  const RequestMethodFilter(this.requestMethod);

  final RequestMethod requestMethod;

  @override
  bool Function(RequestDetails requestDetails) get requestFilter =>
      (requestDetails) => requestDetails.requestMethod == requestMethod;
}

class RequestUrlFilter implements RequestFilter {
  const RequestUrlFilter(this.url);

  final String url;

  @override
  bool Function(RequestDetails requestDetails) get requestFilter =>
      (requestDetails) => requestDetails.url
          .trim()
          .toLowerCase()
          .contains(url.trim().toLowerCase());
}

class RequestStatusCodeFilter implements RequestFilter {
  const RequestStatusCodeFilter(this.statusCode);

  final int statusCode;

  @override
  bool Function(RequestDetails requestDetails) get requestFilter =>
      (requestDetails) => requestDetails.statusCode == statusCode;
}
