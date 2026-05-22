import 'package:flutter_test/flutter_test.dart';
import 'package:requests_inspector/requests_inspector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InspectorController', () {
    late InspectorController inspectorController;

    setUp(() {
      inspectorController = InspectorController(
        enabled: true,
        showInspectorOn: ShowInspectorOn.Both,
      );
      inspectorController.clearAllRequests();
    });

    test('Initial values should be as expected', () {
      expect(inspectorController.isDarkMode, true);
      expect(inspectorController.isTreeView, true);
      expect(inspectorController.requestsList, isEmpty);
    });

    test('Should add new request', () {
      var request = RequestDetails(
        url: 'http://example.com',
        requestMethod: RequestMethod.GET,
      );
      inspectorController.addNewRequest(request);
      expect(inspectorController.requestsList.length, 1);
      expect(inspectorController.requestsList.first.url, 'http://example.com');
    });

    test('Should clear all requests', () {
      var request = RequestDetails(
        url: 'http://example.com',
        requestMethod: RequestMethod.GET,
      );
      inspectorController.addNewRequest(request);
      inspectorController.clearAllRequests();
      expect(inspectorController.requestsList, isEmpty);
      expect(inspectorController.selectedRequest, isNull);
    });

    test('Toggle dark mode should change state', () {
      inspectorController.toggleInspectorTheme();
      expect(inspectorController.isDarkMode, false);
      inspectorController.toggleInspectorTheme();
      expect(inspectorController.isDarkMode, true);
    });

    test('Search functionality works correctly', () {
      var request1 = RequestDetails(
        url: 'http://test1.com',
        requestMethod: RequestMethod.GET,
      );
      var request2 = RequestDetails(
        url: 'http://test2.com',
        requestMethod: RequestMethod.GET,
      );
      inspectorController.addNewRequest(request1);
      inspectorController.addNewRequest(request2);
      inspectorController.searchForRequests('test1');

      expect(inspectorController.filteredRequestsList.length, 1);
      expect(inspectorController.filteredRequestsList.first.url, 'http://test1.com');
    });
  });
}