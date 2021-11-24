import 'package:flutter/material.dart';
import 'request_model.dart';

///Singleton
class RequestsInspectorController extends ChangeNotifier {
  factory RequestsInspectorController() => _singleton;
  RequestsInspectorController._internal();
  static final _singleton = RequestsInspectorController._internal();

  final pageController = PageController(
    initialPage: 0,
    // if the viewportFraction is 1.0, the child pages will rebuild automatically
    // but if it less than 1.0, the pages will stay alive
    viewportFraction: 0.9999999,
  );

  int _selectedTab = 0;

  final _requestsList = <RequestDetails>[];
  RequestDetails? _selectedRequested;

  int get selectedTab => _selectedTab;
  List<RequestDetails> get requestsList => _requestsList;
  RequestDetails? get selectedRequested => _selectedRequested;

  set selectedTab(int value) {
    if (_selectedTab == value) return;
    _selectedTab = value;
    notifyListeners();
  }

  set selectedRequested(RequestDetails? value) {
    if (_selectedRequested == value) return;
    _selectedRequested = value;
    _selectedTab = 1;
    notifyListeners();
  }

  void showInspector() => pageController.jumpToPage(1);

  void hideInspector() => pageController.jumpToPage(0);

  void addNewRequest(RequestDetails request) {
    _requestsList.insert(0, request);
    notifyListeners();
  }
}
