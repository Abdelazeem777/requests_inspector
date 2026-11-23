import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:requests_inspector/requests_inspector.dart';

import 'helpers/fakes.dart';
import 'helpers/plugin_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('InspectorController', () {
    late InspectorController inspectorController;

    setUp(() {
      inspectorController = InspectorController(enabled: true);
    });

    // `dispose` also resets the singleton, so every test starts fresh.
    tearDown(() => inspectorController.dispose());

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
      expect(
        inspectorController.filteredRequestsList.first.url,
        'http://test1.com',
      );
    });
  });

  group('InspectorController lifecycle', () {
    test('is a singleton until it is disposed', () {
      final first = InspectorController(
        enabled: true,
        showInspectorOn: ShowInspectorOn.LongPress,
      );
      expect(InspectorController(), same(first));

      first.dispose();
      final second = InspectorController(
        enabled: true,
        showInspectorOn: ShowInspectorOn.LongPress,
      );
      expect(second, isNot(same(first)));
      second.dispose();
    });

    test('listens to the accelerometer only when shaking is allowed', () async {
      for (final mode in ShowInspectorOn.values) {
        final controller = InspectorController(
          enabled: true,
          showInspectorOn: mode,
        );
        await pumpEventQueue();
        expect(
          FakeSensors.isListening,
          mode != ShowInspectorOn.LongPress,
          reason: '$mode',
        );

        controller.dispose();
        await pumpEventQueue();
        expect(FakeSensors.isListening, isFalse, reason: '$mode');
      }
    });

    test('a disabled controller can be disposed', () {
      // Same defaults as an `InspectorController()` call made before the
      // RequestsInspector widget created the configured instance.
      final controller = InspectorController();
      expect(controller.dispose, returnsNormally);
    });

    test(
      'uses the configuration of the RequestsInspector even when '
      'InspectorController() was called first',
      () {
        // e.g. a Dio request fired in main() before runApp().
        InspectorController();
        final controller = InspectorController(
          enabled: true,
          showInspectorOn: ShowInspectorOn.LongPress,
        );
        addTearDown(controller.dispose);

        controller.addNewRequest(sampleRequest());

        expect(controller.requestsList, hasLength(1));
      },
      skip:
          'Known bug: the singleton keeps the arguments of the first call, '
          'so an early InspectorController() leaves the inspector disabled '
          'for the whole app session.',
    );
  });

  group('InspectorController state', () {
    late InspectorController controller;
    late int notifications;

    setUp(() {
      controller = InspectorController(
        enabled: true,
        showInspectorOn: ShowInspectorOn.LongPress,
      );
      notifications = 0;
      controller.addListener(() => notifications++);
    });

    tearDown(() => controller.dispose());

    group('requests list', () {
      test('ignores new requests while disabled', () {
        controller.dispose();
        controller = InspectorController(
          enabled: false,
          showInspectorOn: ShowInspectorOn.LongPress,
        );

        controller.addNewRequest(sampleRequest());

        expect(controller.requestsList, isEmpty);
      });

      test('keeps the newest request first and notifies listeners', () {
        final older = sampleRequest(url: 'https://api.example.com/older');
        final newer = sampleRequest(url: 'https://api.example.com/newer');

        controller
          ..addNewRequest(older)
          ..addNewRequest(newer);

        expect(controller.requestsList, [newer, older]);
        expect(notifications, 2);
      });

      test('clearAllRequests also clears the selection', () {
        final request = sampleRequest();
        controller
          ..addNewRequest(request)
          ..selectedRequest = request;
        notifications = 0;

        controller.clearAllRequests();

        expect(controller.requestsList, isEmpty);
        expect(controller.selectedRequest, isNull);
        expect(notifications, 1);

        controller.clearAllRequests();
        expect(notifications, 1, reason: 'nothing left to clear');
      });
    });

    group('list filters', () {
      final getUsers = sampleRequest(
        url: 'https://api.example.com/users',
        requestMethod: RequestMethod.GET,
        statusCode: 200,
      );
      final postUsers = sampleRequest(
        url: 'https://api.example.com/users',
        requestMethod: RequestMethod.POST,
        statusCode: 201,
      );
      final getPosts = sampleRequest(
        url: 'https://api.example.com/posts',
        requestMethod: RequestMethod.GET,
        statusCode: 404,
      );

      setUp(() {
        controller
          ..addNewRequest(getUsers)
          ..addNewRequest(postUsers)
          ..addNewRequest(getPosts);
      });

      test('without filters every request is listed', () {
        expect(controller.areAnyFiltersApplied, isFalse);
        expect(controller.filteredRequestsList, [
          getPosts,
          postUsers,
          getUsers,
        ]);
      });

      test('filters by method, status code and URL together', () {
        controller.setRequestMethodFilter(RequestMethod.GET);
        expect(controller.filteredRequestsList, [getPosts, getUsers]);

        controller.setStatusCodeFilter(200);
        expect(controller.filteredRequestsList, [getUsers]);

        controller
          ..setStatusCodeFilter(null)
          ..searchForRequests('  POSTS ');
        expect(controller.filteredRequestsList, [getPosts]);
        expect(controller.areAnyFiltersApplied, isTrue);
      });

      test('clearFilters keeps the URL search, clearSearch removes it', () {
        controller
          ..setRequestMethodFilter(RequestMethod.POST)
          ..setStatusCodeFilter(201)
          ..searchForRequests('users')
          ..clearFilters();

        expect(controller.filterRequestMethod, isNull);
        expect(controller.filterStatusCode, isNull);
        expect(controller.searchUrlQuery, 'users');
        expect(controller.filteredRequestsList, [postUsers, getUsers]);

        controller.clearSearch();
        expect(controller.searchUrlQuery, isEmpty);
        expect(controller.areAnyFiltersApplied, isFalse);
      });

      test('setting the same value does not notify again', () {
        notifications = 0;
        controller
          ..setRequestMethodFilter(RequestMethod.GET)
          ..setRequestMethodFilter(RequestMethod.GET)
          ..setStatusCodeFilter(200)
          ..setStatusCodeFilter(200)
          ..searchForRequests('a')
          ..searchForRequests('a')
          ..clearSearch()
          ..clearSearch();

        expect(notifications, 4);
      });
    });

    group('tabs and selection', () {
      test('selecting a request opens the details tab', () {
        final request = sampleRequest();

        controller.selectedRequest = request;

        expect(controller.selectedRequest, request);
        expect(controller.selectedTab, 1);
        expect(notifications, 1);

        controller.selectedRequest = request;
        expect(notifications, 1, reason: 'already selected and visible');

        controller.selectedTab = 0;
        controller.selectedTab = 0;
        expect(controller.selectedTab, 0);
        expect(notifications, 2);
      });
    });

    group('stoppers', () {
      test('enabling stoppers notifies once per change', () {
        controller
          ..requestStopperEnabled = true
          ..requestStopperEnabled = true
          ..responseStopperEnabled = true
          ..responseStopperEnabled = true;

        expect(controller.requestStopperEnabled, isTrue);
        expect(controller.responseStopperEnabled, isTrue);
        expect(notifications, 2);
      });

      test('request stopper filters are trimmed and clearable', () {
        expect(controller.hasRequestStopperFilters, isFalse);

        controller.setRequestStopperFilterUrl('   ');
        expect(controller.requestStopperFilterUrl, isNull);
        expect(controller.hasRequestStopperFilters, isFalse);

        controller
          ..setRequestStopperFilterUrl('  /users ')
          ..setRequestStopperFilterMethod(RequestMethod.POST);
        expect(controller.requestStopperFilterUrl, '/users');
        expect(controller.requestStopperFilterMethod, RequestMethod.POST);
        expect(controller.hasRequestStopperFilters, isTrue);

        expect(
          controller.shouldStopRequest(
            sampleRequest(
              requestMethod: RequestMethod.POST,
              url: 'https://api.example.com/users',
            ),
          ),
          isTrue,
        );
        expect(
          controller.shouldStopRequest(
            sampleRequest(
              requestMethod: RequestMethod.GET,
              url: 'https://api.example.com/users',
            ),
          ),
          isFalse,
        );

        controller.clearRequestStopperFilters();
        expect(controller.requestStopperFilterMethod, isNull);
        expect(controller.requestStopperFilterUrl, isNull);
        expect(controller.shouldStopRequest(sampleRequest()), isTrue);
      });

      test('response stopper filters are trimmed and clearable', () {
        expect(controller.hasResponseStopperFilters, isFalse);

        controller
          ..setResponseStopperFilterUrl(' ')
          ..setResponseStopperFilterStatusCode(404);
        expect(controller.responseStopperFilterUrl, isNull);
        expect(controller.responseStopperFilterStatusCode, 404);
        expect(controller.hasResponseStopperFilters, isTrue);

        controller.setResponseStopperFilterUrl(' /posts ');
        expect(controller.responseStopperFilterUrl, '/posts');

        const notFoundPosts = ResponseDetails(
          statusCode: 404,
          url: 'https://api.example.com/posts',
        );
        const okPosts = ResponseDetails(
          statusCode: 200,
          url: 'https://api.example.com/posts',
        );
        expect(controller.shouldStopResponse(notFoundPosts), isTrue);
        expect(controller.shouldStopResponse(okPosts), isFalse);

        controller.clearResponseStopperFilters();
        expect(controller.hasResponseStopperFilters, isFalse);
        expect(controller.shouldStopResponse(okPosts), isTrue);
      });

      test('editRequest returns null without a stopping callback', () async {
        expect(await controller.editRequest(sampleRequest()), isNull);
        expect(
          await controller.editResponse(
            const ResponseDetails(statusCode: 200, url: 'u', responseBody: {}),
          ),
          isNull,
        );
      });

      test('editRequest and editResponse delegate to the callbacks', () async {
        controller.dispose();
        final edited = sampleRequest(url: 'https://api.example.com/edited');
        final seenResponses = <ResponseDetails>[];
        controller = InspectorController(
          enabled: true,
          showInspectorOn: ShowInspectorOn.LongPress,
          onStoppingRequest: (_) async => edited,
          onStoppingResponse: (response) async {
            seenResponses.add(response);
            return response.copyWith(statusCode: 418);
          },
        );

        expect(await controller.editRequest(sampleRequest()), edited);

        for (final body in <Object>[
          {'a': 1},
          [1, 2],
          'text',
        ]) {
          final result = await controller.editResponse(
            ResponseDetails(statusCode: 200, url: 'u', responseBody: body),
          );
          expect(result?.statusCode, 418, reason: '${body.runtimeType}');
        }

        // Only Map, List and String bodies can be edited in the dialog.
        expect(
          await controller.editResponse(
            const ResponseDetails(statusCode: 200, url: 'u', responseBody: 1),
          ),
          isNull,
        );
        expect(seenResponses, hasLength(3));
      });
    });

    group('view options', () {
      test('default values come from the constructor', () {
        controller.dispose();
        controller = InspectorController(
          enabled: true,
          showInspectorOn: ShowInspectorOn.LongPress,
          defaultIsDarkMode: false,
          defaultTreeViewEnabled: false,
          defaultExpandChildren: false,
        );

        expect(controller.isDarkMode, isFalse);
        expect(controller.isTreeView, isFalse);
        expect(controller.expandChildren, isFalse);
      });

      test('toggles flip the value and notify', () {
        controller
          ..toggleInspectorTheme()
          ..toggleInspectorJsonView()
          ..toggleExpandChildren();

        expect(controller.isDarkMode, isFalse);
        expect(controller.isTreeView, isFalse);
        expect(controller.expandChildren, isFalse);
        expect(notifications, 3);
      });
    });

    group('details search', () {
      final request = sampleRequest(
        url: 'https://api.example.com/needle',
        headers: {'x-needle': 'NEEDLE'},
        queryParameters: null,
        requestBody: {'needle': 'needle'},
        graphqlRequestVars: {'id': 'needle'},
        responseBody: {
          'items': ['Needle'],
        },
      );

      test('counts case-insensitive matches in every section', () {
        controller
          ..selectedRequest = request
          ..toggleSearchVisibility()
          ..updateSearchQuery('NeEdLe');

        // URL 1 + headers 2 + body 2 + graphql vars 1 + response 1
        expect(controller.totalMatches, 7);
        expect(controller.currentMatchIndex, 0);
      });

      test('is empty without a selected request or query', () {
        controller.updateSearchQuery('needle');
        expect(controller.totalMatches, 0);

        controller
          ..selectedRequest = request
          ..updateSearchQuery('');
        expect(controller.totalMatches, 0);
      });

      test('recounts when another request is selected', () {
        controller
          ..selectedRequest = request
          ..updateSearchQuery('needle');
        expect(controller.totalMatches, 7);

        controller.selectedRequest = sampleRequest();
        expect(controller.totalMatches, 0);
      });

      test('next and previous wrap around', () {
        controller
          ..selectedRequest = request
          ..updateSearchQuery('needle');

        controller.previousMatch();
        expect(controller.currentMatchIndex, 6);
        controller.nextMatch();
        expect(controller.currentMatchIndex, 0);
        controller.nextMatch();
        expect(controller.currentMatchIndex, 1);
      });

      test('next and previous do nothing without matches', () {
        controller
          ..nextMatch()
          ..previousMatch();
        expect(controller.currentMatchIndex, -1);
        expect(notifications, 0);
      });

      test('hiding the search bar clears the query', () {
        controller
          ..selectedRequest = request
          ..toggleSearchVisibility()
          ..updateSearchQuery('needle');
        expect(controller.isSearchVisible, isTrue);

        controller.toggleSearchVisibility();

        expect(controller.isSearchVisible, isFalse);
        expect(controller.searchQuery, isEmpty);
        expect(controller.totalMatches, 0);
      });

      test('updateMatchCount only notifies on change', () {
        controller
          ..updateMatchCount(3)
          ..updateMatchCount(3);

        expect(controller.totalMatches, 3);
        expect(notifications, 1);
      });
    });
  });

  group('InspectorController.runAgain', () {
    late HttpServer server;
    late InspectorController controller;
    final received = <Map<String, Object?>>[];

    setUp(() async {
      // flutter_test answers every dart:io HttpClient request with a 400;
      // this test talks to a local in-process server instead.
      HttpOverrides.global = null;
      received.clear();
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        received.add({
          'method': request.method,
          'path': request.uri.path,
          'query': request.uri.queryParameters,
          'x-test': request.headers.value('x-test'),
          'body': await utf8.decodeStream(request),
        });
        request.response
          ..statusCode = 201
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'ok': true}));
        await request.response.close();
      });
      controller = InspectorController(
        enabled: true,
        showInspectorOn: ShowInspectorOn.LongPress,
      );
    });

    tearDown(() async {
      controller.dispose();
      await server.close(force: true);
    });

    test('does nothing without a selected request', () async {
      await controller.runAgain();
      expect(received, isEmpty);
    });

    test('re-sends the selected request and keeps the new response', () async {
      final original = sampleRequest(
        requestMethod: RequestMethod.POST,
        url: 'http://127.0.0.1:${server.port}/items',
        headers: {'x-test': 'yes'},
        queryParameters: {'q': 'a b'},
        requestBody: {'name': 'x'},
        statusCode: 500,
        responseBody: 'old',
      );
      controller.selectedRequest = original;

      await controller.runAgain();

      expect(received.single, {
        'method': 'POST',
        'path': '/items',
        'query': {'q': 'a b'},
        'x-test': 'yes',
        'body': '{"name":"x"}',
      });
      final updated = controller.selectedRequest!;
      expect(updated.statusCode, 201);
      expect(updated.responseBody, {'ok': true});
      expect(updated.url, original.url);
      expect(updated.sentTime.isAfter(original.sentTime), isTrue);
      expect(updated.receivedTime!.isBefore(updated.sentTime), isFalse);
    });
  });
}
