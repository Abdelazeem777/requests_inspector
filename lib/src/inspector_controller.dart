import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:requests_inspector/src/shake.dart';
import 'package:share_plus/share_plus.dart';

import '../requests_inspector.dart';
import 'curl_command_generator.dart';
import 'har_generator.dart';
import 'json_pretty_converter.dart';
import 'helpers/inspector_helper.dart';
import 'enums/share_type_enum.dart';

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
    if (_enabled && _allowShaking)
      _shakeDetector = ShakeDetector.autoStart(
        onPhoneShake: showInspector,
        minimumShakeCount: 3,
      );
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

  bool _isSearchVisible = false;
  String _searchQuery = '';
  int _totalMatches = 0;
  int _currentMatchIndex = -1;

  int get selectedTab => _selectedTab;

  bool get requestStopperEnabled => _requestStopperEnabled;

  bool get responseStopperEnabled => _responseStopperEnabled;

  bool get isDarkMode => _isDarkMode;

  bool get isTreeView => _isTreeView;

  List<RequestDetails> get requestsList => _requestsList;

  RequestDetails? get selectedRequest => _selectedRequest;

  bool get isSearchVisible => _isSearchVisible;

  String get searchQuery => _searchQuery;

  int get totalMatches => _totalMatches;

  int get currentMatchIndex => _currentMatchIndex;

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
    _updateTotalMatches();
    notifyListeners();
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

  void toggleSearchVisibility() {
    _isSearchVisible = !_isSearchVisible;
    if (!_isSearchVisible) {
      _searchQuery = '';
      _totalMatches = 0;
    }
    notifyListeners();
  }

  void updateMatchCount(int count) {
    if (_totalMatches == count) return;
    _totalMatches = count;
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    _updateTotalMatches();
    notifyListeners();
  }

  void nextMatch() {
    if (_totalMatches == 0) return;
    _currentMatchIndex = (_currentMatchIndex + 1) % _totalMatches;
    notifyListeners();
  }

  void previousMatch() {
    if (_totalMatches == 0) return;
    _currentMatchIndex =
        (_currentMatchIndex - 1 + _totalMatches) % _totalMatches;
    notifyListeners();
  }

  void _updateTotalMatches() {
    if (_searchQuery.isEmpty || _selectedRequest == null) {
      _totalMatches = 0;
      return;
    }

    final allText = _extractAllText(_selectedRequest!);
    final query = _searchQuery.toLowerCase();
    final text = allText.toLowerCase();

    var count = 0;
    var index = text.indexOf(query);
    while (index != -1) {
      count++;
      index = text.indexOf(query, index + query.length);
    }
    _totalMatches = count;
    _currentMatchIndex = count > 0 ? 0 : -1;
  }

  String _extractAllText(RequestDetails request) {
    final converter = JsonPrettyConverter();
    final parts = <String>[];

    final sentTimeText = InspectorHelper.extractTimeText(request.sentTime);
    var text = 'Sent at: $sentTimeText';

    if (request.receivedTime != null) {
      final receivedTimeText =
          InspectorHelper.extractTimeText(request.receivedTime!);
      final durationText = InspectorHelper.calculateDuration(
          request.sentTime, request.receivedTime!);
      text += '\nReceived at: $receivedTimeText\nDuration: $durationText';
    }

    text += '\n\nURL: ${request.url}';
    parts.add(text);

    if (request.headers != null) parts.add(converter.convert(request.headers));
    if (request.queryParameters != null) {
      parts.add(converter.convert(request.queryParameters));
    }
    if (request.requestBody != null) {
      parts.add(converter.convert(request.requestBody));
    }
    if (request.graphqlRequestVars != null) {
      parts.add(converter.convert(request.graphqlRequestVars));
    }
    if (request.responseBody != null) {
      parts.add(converter.convert(request.responseBody));
    }

    return parts.join('\n');
  }
}
