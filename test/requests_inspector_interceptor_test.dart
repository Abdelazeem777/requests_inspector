import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:requests_inspector/requests_inspector.dart';

import 'helpers/fakes.dart';

void main() {
  late InspectorController controller;

  InspectorController createController({
    StoppingRequestCallback? onStoppingRequest,
    StoppingResponseCallback? onStoppingResponse,
  }) => InspectorController(
    enabled: true,
    showInspectorOn: ShowInspectorOn.LongPress,
    onStoppingRequest: onStoppingRequest,
    onStoppingResponse: onStoppingResponse,
  );

  setUp(() => controller = createController());

  tearDown(() => controller.dispose());

  RequestDetails onlyLogged() => controller.requestsList.single;

  group('RequestsInspectorInterceptor.onResponse', () {
    test('logs a successful request with its response', () async {
      final adapter = FakeHttpClientAdapter.json({'id': 7}, statusCode: 201);
      final dio = inspectedDio(adapter);

      final before = DateTime.now();
      final response = await dio.post(
        '/users',
        queryParameters: {'page': 2},
        data: {'name': 'John'},
        options: Options(headers: {'x-test': 'yes'}),
      );

      expect(response.data, {'id': 7});
      final logged = onlyLogged();
      expect(logged.requestMethod, RequestMethod.POST);
      expect(logged.requestName, 'USERS');
      expect(logged.url, 'https://api.example.com/users');
      expect(logged.queryParameters, {'page': 2});
      expect(logged.headers, containsPair('x-test', 'yes'));
      expect(logged.requestBody, {'name': 'John'});
      expect(logged.statusCode, 201);
      expect(logged.responseBody, {'id': 7});
      expect(logged.sentTime.isBefore(before), isFalse);
      expect(logged.receivedTime!.isBefore(logged.sentTime), isFalse);
    });

    test('logs every supported method', () async {
      final dio = inspectedDio(FakeHttpClientAdapter.json({}));

      await dio.get('/a');
      await dio.post('/a');
      await dio.put('/a');
      await dio.patch('/a');
      await dio.delete('/a');

      expect(controller.requestsList.map((r) => r.requestMethod), [
        RequestMethod.DELETE,
        RequestMethod.PATCH,
        RequestMethod.PUT,
        RequestMethod.POST,
        RequestMethod.GET,
      ]);
    });

    test('merges query parameters written in the path', () async {
      final dio = inspectedDio(FakeHttpClientAdapter.json({}));

      await dio.get('/search?lang=en', queryParameters: {'q': 'dart'});

      expect(onlyLogged().url, 'https://api.example.com/search');
      expect(onlyLogged().queryParameters, {'lang': 'en', 'q': 'dart'});
    });

    test('does not break HEAD requests', () async {
      final dio = inspectedDio(FakeHttpClientAdapter.json(''));

      final response = await dio
          .head('/users')
          .timeout(const Duration(seconds: 2));

      expect(response.statusCode, 200);
    });

    test('does not break OPTIONS requests', () async {
      final dio = inspectedDio(FakeHttpClientAdapter.json(''));

      final response = await dio
          .request('/users', options: Options(method: 'OPTIONS'))
          .timeout(const Duration(seconds: 2));

      expect(response.statusCode, 200);
      expect(onlyLogged().requestMethod, RequestMethod.OPTIONS);
    });

    test('does not break requests with an unknown method', () async {
      final dio = inspectedDio(FakeHttpClientAdapter.json(''));

      final response = await dio
          .request('/users', options: Options(method: 'TRACE'))
          .timeout(const Duration(seconds: 2));

      expect(response.statusCode, 200);
      expect(controller.requestsList, isEmpty);
    });
  });

  group('RequestsInspectorInterceptor.onError', () {
    test('logs a bad response with its status code and body', () async {
      final dio = inspectedDio(
        FakeHttpClientAdapter.json({'error': 'missing'}, statusCode: 404),
      );

      await expectLater(
        dio.get('/users/1'),
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.badResponse,
          ),
        ),
      );

      final logged = onlyLogged();
      expect(logged.url, 'https://api.example.com/users/1');
      expect(logged.statusCode, 404);
      expect(logged.responseBody, {'error': 'missing'});
      expect(logged.receivedTime, isNotNull);
    });

    test(
      'logs a connection failure with status 0 and the error message',
      () async {
        final dio = inspectedDio(
          FakeHttpClientAdapter(
            (options) => Future.error(
              DioException.connectionError(
                requestOptions: options,
                reason: 'no internet',
              ),
            ),
          ),
        );

        await expectLater(dio.get('/users'), throwsA(isA<DioException>()));

        final logged = onlyLogged();
        expect(logged.statusCode, 0);
        expect(logged.responseBody, contains('no internet'));
      },
    );
  });

  group('request stopper', () {
    test('is skipped while the request stopper is disabled', () async {
      var calls = 0;
      controller.dispose();
      controller = createController(
        onStoppingRequest: (_) async {
          calls++;
          return null;
        },
      );
      final dio = inspectedDio(FakeHttpClientAdapter.json({}));

      await dio.get('/users');

      expect(calls, 0);
    });

    test('sends the original request when the editor returns null', () async {
      RequestDetails? stopped;
      controller.dispose();
      controller = createController(
        onStoppingRequest: (details) async {
          stopped = details;
          return null;
        },
      )..requestStopperEnabled = true;
      final adapter = FakeHttpClientAdapter.json({});

      await inspectedDio(adapter).get('/users', queryParameters: {'a': '1'});

      expect(stopped!.url, 'https://api.example.com/users');
      expect(stopped!.queryParameters, {'a': '1'});
      expect(
        adapter.requests.single.uri.toString(),
        'https://api.example.com/users?a=1',
      );
    });

    test(
      'shows the URL without its query and the whole query to edit',
      () async {
        RequestDetails? stopped;
        controller.dispose();
        controller = createController(
          onStoppingRequest: (details) async {
            stopped = details;
            return null;
          },
        )..requestStopperEnabled = true;

        await inspectedDio(
          FakeHttpClientAdapter.json({}),
        ).get('/users?lang=en&tag=a&tag=b', queryParameters: {'page': 2});

        expect(stopped!.url, 'https://api.example.com/users');
        expect(stopped!.queryParameters, {
          'lang': 'en',
          'tag': ['a', 'b'],
          'page': 2,
        });
      },
    );

    test('sends the edited request', () async {
      controller.dispose();
      controller = createController(
        onStoppingRequest: (details) async => details.copyWith(
          requestMethod: RequestMethod.PUT,
          url: 'https://other.example.com/edited',
          headers: {'x-edited': 'true'},
          requestBody: {'edited': true},
        ),
      )..requestStopperEnabled = true;
      final adapter = FakeHttpClientAdapter.json({'ok': true});

      await inspectedDio(adapter).post('/users', data: {'name': 'John'});

      final sent = adapter.requests.single;
      expect(sent.method, 'PUT');
      expect(sent.uri.toString(), 'https://other.example.com/edited');
      expect(sent.headers, containsPair('x-edited', 'true'));
      expect(sent.data, {'edited': true});
      expect(onlyLogged().requestMethod, RequestMethod.PUT);
      expect(onlyLogged().url, 'https://other.example.com/edited');
    });

    Future<String> sentUri(
      Future<RequestDetails?> Function(RequestDetails details) edit,
    ) async {
      controller.dispose();
      controller = createController(onStoppingRequest: edit)
        ..requestStopperEnabled = true;
      final adapter = FakeHttpClientAdapter.json({});

      await inspectedDio(
        adapter,
      ).get('/users?lang=en', queryParameters: {'a': '1'});

      return adapter.requests.single.uri.toString();
    }

    test('sends no query when the query parameters are cleared', () async {
      expect(
        await sentUri(
          (details) async =>
              details.copyWith(queryParameters: <String, dynamic>{}),
        ),
        'https://api.example.com/users',
      );
    });

    test('sends the query parameters exactly as edited', () async {
      expect(
        await sentUri(
          (details) async => details.copyWith(queryParameters: {'a': '2'}),
        ),
        'https://api.example.com/users?a=2',
      );
    });

    test('sends the edited URL with the query parameters', () async {
      expect(
        await sentUri(
          (details) async =>
              details.copyWith(url: 'https://other.example.com/v2/users'),
        ),
        'https://other.example.com/v2/users?lang=en&a=1',
      );
    });

    test('sends an unedited request as it was', () async {
      Future<String> send({required bool stop}) async {
        controller.dispose();
        controller = createController(onStoppingRequest: (d) async => d)
          ..requestStopperEnabled = stop;
        final adapter = FakeHttpClientAdapter.json({});
        await inspectedDio(adapter).get(
          '/search?lang=en&tag=a&tag=b',
          queryParameters: {
            'q': 'a b&c',
            'page': 2,
            'ids': [1, 2],
          },
        );
        return adapter.requests.single.uri.toString();
      }

      expect(await send(stop: true), await send(stop: false));
    });

    test('keeps query parameters when the edited request is sent', () async {
      controller.dispose();
      controller = createController(
        onStoppingRequest: (details) async => details,
      )..requestStopperEnabled = true;
      final adapter = FakeHttpClientAdapter.json({});

      await inspectedDio(adapter).get('/users', queryParameters: {'a': '1'});

      expect(
        adapter.requests.single.uri.toString(),
        'https://api.example.com/users?a=1',
      );
    });
  });

  group('response stopper', () {
    test(
      'receives the original response when the editor returns null',
      () async {
        ResponseDetails? stopped;
        controller.dispose();
        controller = createController(
          onStoppingResponse: (details) async {
            stopped = details;
            return null;
          },
        )..responseStopperEnabled = true;

        final response = await inspectedDio(
          FakeHttpClientAdapter.json({'id': 1}),
        ).get('/users', queryParameters: {'a': '1'});

        expect(response.data, {'id': 1});
        expect(stopped!.url, 'https://api.example.com/users');
        expect(stopped!.statusCode, 200);
        expect(stopped!.responseBody, {'id': 1});
        expect(stopped!.headers, contains('content-type'));
      },
    );

    test('lets the app receive the edited response', () async {
      controller.dispose();
      controller = createController(
        onStoppingResponse: (details) async => details.copyWith(
          statusCode: 202,
          responseBody: {'edited': true},
          headers: {'x-edited': 'yes'},
        ),
      )..responseStopperEnabled = true;

      final response = await inspectedDio(
        FakeHttpClientAdapter.json({'id': 1}),
      ).get('/u');

      expect(response.statusCode, 202);
      expect(response.data, {'edited': true});
      expect(response.headers.value('x-edited'), 'yes');
      expect(onlyLogged().statusCode, 202);
      expect(onlyLogged().responseBody, {'edited': true});
    });

    test('does not stop responses whose body cannot be edited', () async {
      var calls = 0;
      controller.dispose();
      controller = createController(
        onStoppingResponse: (details) async {
          calls++;
          return null;
        },
      )..responseStopperEnabled = true;

      await inspectedDio(FakeHttpClientAdapter.json(42)).get('/count');

      expect(calls, 0);
      expect(onlyLogged().responseBody, 42);
    });
  });
}
