import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:requests_inspector/src/debouncer.dart';
import 'package:requests_inspector/src/shake.dart';
import 'package:requests_inspector/src/stopper_filter.dart';
import 'package:share_plus/share_plus.dart';

import '../requests_inspector.dart';
import 'curl_command_generator.dart';
import 'har_generator.dart';
import 'json_pretty_converter.dart';
import 'enums/share_type_enum.dart';
import 'requests_filter.dart';

typedef StoppingRequestCallback = Future<RequestDetails?> Function(
    RequestDetails requestDetails);

typedef StoppingResponseCallback = Future<ResponseDetails?> Function(
    ResponseDetails responseDetails);

///Singleton
class InspectorController extends ChangeNotifier {
  factory InspectorController({
    bool enabled = false,
    ShowInspectorOn showInspectorOn = ShowInspectorOn.Shaking,
    StoppingRequestCallback? onStoppingRequest,
    StoppingResponseCallback? onStoppingResponse,
    bool defaultTreeViewEnabled = true,
  }) =>
      _singleton ??= InspectorController._internal(
        enabled: enabled,
        showInspectorOn: showInspectorOn,
        onStoppingRequest: onStoppingRequest,
        onStoppingResponse: onStoppingResponse,
        defaultTreeViewEnabled: defaultTreeViewEnabled,
      );

  InspectorController._internal({
    required bool enabled,
    required ShowInspectorOn showInspectorOn,
    StoppingRequestCallback? onStoppingRequest,
    StoppingResponseCallback? onStoppingResponse,
    required bool defaultTreeViewEnabled,
  })  : _enabled = enabled,
        _showInspectorOn = showInspectorOn,
        _onStoppingRequest = onStoppingRequest,
        _isTreeView = defaultTreeViewEnabled,
        _onStoppingResponse = onStoppingResponse {
    if (_enabled && _allowShaking) {
      _shakeDetector = ShakeDetector.autoStart(
        onPhoneShake: showInspector,
        minimumShakeCount: 3,
      );
    }
  }

  static InspectorController? _singleton;

  late final bool _enabled;
  late final ShowInspectorOn _showInspectorOn;
  late final ShakeDetector _shakeDetector;
  StoppingRequestCallback? _onStoppingRequest;
  StoppingResponseCallback? _onStoppingResponse;

  final _dio = Dio(BaseOptions(validateStatus: (_) => true));
  final pageController = PageController(
    initialPage: 0,
    // if the viewportFraction is 1.0, the child pages will rebuild automatically
    // but if it less than 1.0, the pages will stay alive
    viewportFraction: 0.9999999,
  );

  int _selectedTab = 0;
  bool _requestStopperEnabled = false;
  bool _responseStopperEnabled = false;
  bool _isDarkMode = true;
  bool _isTreeView = true;

  final _requestsList = <RequestDetails>[];
  RequestDetails? _selectedRequest;

  // Search & Filters state
  String _searchUrlQuery = '';
  RequestMethod? _filterRequestMethod;
  int? _filterStatusCode;
  final searchDebouncer = Debouncer(milliseconds: 500);
  // ------------------------------

  // Stoppers Filter State
  RequestMethod? _requestStopperFilterMethod;
  String? _requestStopperFilterUrl;
  int? _responseStopperFilterStatusCode;
  String? _responseStopperFilterUrl;
  // ------------------------------

  RequestMethod? get requestStopperFilterMethod => _requestStopperFilterMethod;
  String? get requestStopperFilterUrl => _requestStopperFilterUrl;
  int? get responseStopperFilterStatusCode => _responseStopperFilterStatusCode;
  String? get responseStopperFilterUrl => _responseStopperFilterUrl;

  bool get hasRequestStopperFilters =>
      _requestStopperFilterMethod != null ||
      (_requestStopperFilterUrl != null &&
          _requestStopperFilterUrl!.trim().isNotEmpty);

  bool get hasResponseStopperFilters =>
      _responseStopperFilterStatusCode != null ||
      (_responseStopperFilterUrl != null &&
          _responseStopperFilterUrl!.trim().isNotEmpty);

  int get selectedTab => _selectedTab;

  bool get requestStopperEnabled => _requestStopperEnabled;

  bool get responseStopperEnabled => _responseStopperEnabled;

  bool get isDarkMode => _isDarkMode;

  bool get isTreeView => _isTreeView;

  List<RequestDetails> get requestsList => _requestsList;

  RequestDetails? get selectedRequest => _selectedRequest;

  String get searchUrlQuery => _searchUrlQuery;

  RequestMethod? get filterRequestMethod => _filterRequestMethod;

  int? get filterStatusCode => _filterStatusCode;

  bool get areAnyFiltersApplied =>
      searchUrlQuery.trim().isNotEmpty ||
      filterRequestMethod != null ||
      filterStatusCode != null;

  // Computed filtered + searched list
  List<RequestDetails> get filteredRequestsList {
    Iterable<RequestDetails> list = [..._requestsList];

    // Build filters list
    final filters = <RequestFilter>[];
    if (_filterRequestMethod != null) {
      filters.add(RequestMethodFilter(_filterRequestMethod!));
    }

    if (_filterStatusCode != null) {
      filters.add(RequestStatusCodeFilter(_filterStatusCode!));
    }

    if (_searchUrlQuery.trim().isNotEmpty) {
      filters.add(RequestUrlFilter(_searchUrlQuery));
    }

    // Apply filters
    for (final f in filters) {
      list = list.where(f.requestFilter);
    }

    return list.toList(growable: false);
  }

  bool get _allowShaking => [
        ShowInspectorOn.Shaking,
        ShowInspectorOn.Both,
      ].contains(_showInspectorOn);

  set selectedTab(int value) {
    if (_selectedTab == value) return;
    _selectedTab = value;
    notifyListeners();
  }

  set requestStopperEnabled(bool value) {
    if (_requestStopperEnabled == value) return;
    _requestStopperEnabled = value;
    notifyListeners();
  }

  set responseStopperEnabled(bool value) {
    if (_responseStopperEnabled == value) return;
    _responseStopperEnabled = value;
    notifyListeners();
  }

  set selectedRequest(RequestDetails? value) {
    if (_selectedRequest == value && _selectedTab == 1) return;
    _selectedRequest = value;
    _selectedTab = 1;
    notifyListeners();
  }

  // setters for search & filters
  void setSearchQuery(String value) {
    if (_searchUrlQuery == value) return;
    _searchUrlQuery = value;
    notifyListeners();
  }

  void setRequestMethodFilter(RequestMethod? method) {
    if (_filterRequestMethod == method) return;
    _filterRequestMethod = method;
    notifyListeners();
  }

  void setStatusCodeFilter(int? statusCode) {
    if (_filterStatusCode == statusCode) return;
    _filterStatusCode = statusCode;
    notifyListeners();
  }

  void clearFilters() {
    _filterRequestMethod = null;
    _filterStatusCode = null;
    notifyListeners();
  }

  void clearSearch() {
    if (_searchUrlQuery.isEmpty) return;
    _searchUrlQuery = '';
    notifyListeners();
  }

  void setRequestStopperFilterMethod(RequestMethod? method) {
    if (_requestStopperFilterMethod == method) return;
    _requestStopperFilterMethod = method;
    notifyListeners();
  }

  void setRequestStopperFilterUrl(String? url) {
    url = url?.trim();
    if (url != null && url.isEmpty) {
      url = null;
    }
    if (_requestStopperFilterUrl == url) return;
    _requestStopperFilterUrl = url;
    notifyListeners();
  }

  void setResponseStopperFilterStatusCode(int? statusCode) {
    if (_responseStopperFilterStatusCode == statusCode) return;
    _responseStopperFilterStatusCode = statusCode;
    notifyListeners();
  }

  void setResponseStopperFilterUrl(String? url) {
    url = url?.trim();
    if (url != null && url.isEmpty) {
      url = null;
    }
    if (_responseStopperFilterUrl == url) return;
    _responseStopperFilterUrl = url;
    notifyListeners();
  }

  void clearRequestStopperFilters() {
    _requestStopperFilterMethod = null;
    _requestStopperFilterUrl = null;
    notifyListeners();
  }

  void clearResponseStopperFilters() {
    _responseStopperFilterStatusCode = null;
    _responseStopperFilterUrl = null;
    notifyListeners();
  }

  bool shouldStopRequest(RequestDetails requestDetails) {
    final filter = RequestStopperFilter(
      requestMethod: _requestStopperFilterMethod,
      urlPattern: _requestStopperFilterUrl,
    );
    return filter.shouldStop(requestDetails);
  }

  bool shouldStopResponse(ResponseDetails responseDetails) {
    final filter = ResponseStopperFilter(
      statusCode: _responseStopperFilterStatusCode,
      urlPattern: _responseStopperFilterUrl,
    );
    return filter.shouldStop(responseDetails);
  }

  void showInspector() => pageController.jumpToPage(1);

  void hideInspector() => pageController.jumpToPage(0);

  void addNewRequest(RequestDetails request) {
    if (!_enabled) return;
    _requestsList.insert(0, request);
    notifyListeners();
  }

  void clearAllRequests() {
    if (_requestsList.isEmpty && _selectedRequest == null) return;
    _requestsList.clear();
    _selectedRequest = null;
    notifyListeners();
  }

  Future<void> runAgain() async {
    if (_selectedRequest == null) return;

    var currentRequest = _selectedRequest!;
    final sentTime = DateTime.now();
    final response = await _dio.request(
      currentRequest.url,
      queryParameters: currentRequest.queryParameters,
      data: currentRequest.requestBody,
      options: Options(
        method: currentRequest.requestMethod.name,
        headers: currentRequest.headers,
      ),
    );
    if (currentRequest != _selectedRequest) return;

    _selectedRequest = currentRequest.copyWith(
      responseBody: response.data,
      statusCode: response.statusCode,
      sentTime: sentTime,
      receivedTime: DateTime.now(),
    );

    notifyListeners();
  }

  void shareSelectedRequest({
    Rect? sharePositionOrigin,
    ShareType shareType = ShareType.NormalLog,
  }) {
    String? requestShareContent;
    if (shareType == ShareType.CurlCommand) {
      final curlCommandGenerator = CurlCommandGenerator(_selectedRequest!);
      requestShareContent = curlCommandGenerator.generate();
    } else if (shareType == ShareType.NormalLog) {
      final requestMap = _selectedRequest!.toMap();
      requestShareContent = _formatMap(requestMap);
    } else if (shareType == ShareType.Har) {
      final curlCommandGenerator = CurlCommandGenerator(_selectedRequest!);
      final curlContent = curlCommandGenerator.generate();

      final harGenerator = HarGenerator();
      requestShareContent = harGenerator.generate(
        request: _selectedRequest!,
        curlCommand: curlContent,
      );
    } else if (shareType == ShareType.HarFile) {
      final curlCommandGenerator = CurlCommandGenerator(_selectedRequest!);
      final curlContent = curlCommandGenerator.generate();

      final harGenerator = HarGenerator();
      final harJson = harGenerator.generate(
        request: _selectedRequest!,
        curlCommand: curlContent,
      );

      final file = XFile.fromData(
        utf8.encode(harJson),
        name: 'request.har',
        mimeType: 'application/json',
      );

      Share.shareXFiles(
        [file],
        sharePositionOrigin: sharePositionOrigin,
      );
      return;
    } else {
      final curlCommandGenerator = CurlCommandGenerator(_selectedRequest!);
      final curlContent = curlCommandGenerator.generate();

      final requestMap = _selectedRequest!.toMap();
      final normalLogContent = _formatMap(requestMap);

      requestShareContent =
          '================[cURL Command]=================\n$curlContent\n\n==================[Normal Log]===================\n$normalLogContent';
    }

    Share.share(
      requestShareContent,
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  @override
  void dispose() {
    if (_allowShaking) _shakeDetector.stopListening();
    searchDebouncer.cancel();
    _singleton = null;
    super.dispose();
  }

  String _formatMap(Map<String, dynamic> requestMap) {
    final converter = JsonPrettyConverter();
    final listOfContent = [
      for (final entry in requestMap.entries) ...[
        '=[ ${entry.key} ]===================\n',
        converter.convert(entry.value),
        '\n\n',
      ],
    ];

    return listOfContent.join();
  }

  Future<RequestDetails?> editRequest(RequestDetails requestDetails) {
    if (!_enabled || _onStoppingRequest == null) return Future.value(null);
    return _onStoppingRequest!(requestDetails);
  }

  Future<ResponseDetails?> editResponse(ResponseDetails responseDetails) {
    if (!_enabled || _onStoppingResponse == null) return Future.value(null);

    if (!['Map', 'String', 'List'].any((e) => responseDetails
        .responseBody.runtimeType
        .toString()
        .replaceFirst('_', '')
        .startsWith(e))) return Future.value(null);

    return _onStoppingResponse!(responseDetails);
  }

  void toggleInspectorTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void toggleInspectorJsonView() {
    _isTreeView = !_isTreeView;
    notifyListeners();
  }
}
