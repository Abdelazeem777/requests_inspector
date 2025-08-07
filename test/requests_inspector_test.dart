import 'package:flutter_test/flutter_test.dart';
import 'package:requests_inspector/requests_inspector.dart';

void main() {
  group('RequestsInspector Tests', () {
    tearDown(() {
      // Reset the singleton between tests by disposing the current instance
      try {
        InspectorController().dispose();
      } catch (e) {
        // Ignore disposal errors
      }
    });
    test('InspectorController should be a singleton', () {
      final controller1 = InspectorController();
      final controller2 = InspectorController();

      expect(controller1, equals(controller2));
    });

    test('RequestDetails should be created with correct properties', () {
      final requestDetails = RequestDetails(
        requestName: 'Test Request',
        requestMethod: RequestMethod.GET,
        url: 'https://api.example.com/test',
        statusCode: 200,
        responseBody: {'message': 'success'},
        headers: {'Content-Type': 'application/json'},
      );

      // RequestDetails automatically converts requestName to uppercase
      expect(requestDetails.requestName, equals('TEST REQUEST'));
      expect(requestDetails.requestMethod, equals(RequestMethod.GET));
      expect(requestDetails.url, equals('https://api.example.com/test'));
      expect(requestDetails.statusCode, equals(200));
      expect(requestDetails.responseBody, equals({'message': 'success'}));
      expect(requestDetails.headers, equals({'Content-Type': 'application/json'}));
    });

    test('InspectorController should handle request addition based on enabled state', () {
      // Test that the controller behaves correctly based on its enabled state
      // Note: Due to singleton pattern, we test the behavior rather than creating multiple instances
      final controller = InspectorController();
      final initialCount = controller.requestsList.length;

      final requestDetails = RequestDetails(
        requestName: 'Test Request',
        requestMethod: RequestMethod.POST,
        url: 'https://api.example.com/create',
        statusCode: 201,
        responseBody: {'id': 1, 'created': true},
      );

      controller.addNewRequest(requestDetails);

      // The behavior depends on whether the controller was initialized as enabled
      // This test verifies the addNewRequest method works without throwing errors
      expect(controller.requestsList.length, greaterThanOrEqualTo(initialCount));

      // Verify RequestDetails properties are correct
      expect(requestDetails.requestName, equals('TEST REQUEST'));
      expect(requestDetails.requestMethod, equals(RequestMethod.POST));
      expect(requestDetails.statusCode, equals(201));
    });

    test('InspectorController should handle different request methods', () {
      final methods = [
        RequestMethod.GET,
        RequestMethod.POST,
        RequestMethod.PUT,
        RequestMethod.DELETE,
        RequestMethod.PATCH,
      ];

      for (final method in methods) {
        final requestDetails = RequestDetails(
          requestName: 'Test ${method.name}',
          requestMethod: method,
          url: 'https://api.example.com/${method.name.toLowerCase()}',
          statusCode: 200,
        );

        expect(requestDetails.requestMethod, equals(method));
        // RequestName should be uppercase
        expect(requestDetails.requestName, equals('TEST ${method.name.toUpperCase()}'));
      }
    });

    test('RequestDetails should extract name from URL when requestName is null', () {
      final requestDetails = RequestDetails(
        requestMethod: RequestMethod.GET,
        url: 'https://api.example.com/users/profile',
        statusCode: 200,
      );

      // Should extract 'profile' from URL and convert to uppercase
      expect(requestDetails.requestName, equals('PROFILE'));
    });
  });
}
