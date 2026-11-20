import 'package:flutter_test/flutter_test.dart';
import 'package:requests_inspector/requests_inspector.dart';
import 'package:requests_inspector/src/requests_filter.dart';
import 'package:requests_inspector/src/stopper_filter.dart';

import 'helpers/fakes.dart';

void main() {
  final getUsers = sampleRequest(
    requestMethod: RequestMethod.GET,
    url: 'https://api.example.com/Users',
    statusCode: 200,
  );
  final postOrders = sampleRequest(
    requestMethod: RequestMethod.POST,
    url: 'https://api.example.com/orders',
    statusCode: 500,
  );

  group('RequestFilter', () {
    test('RequestMethodFilter matches the method', () {
      final filter =
          const RequestMethodFilter(RequestMethod.POST).requestFilter;

      expect(filter(postOrders), isTrue);
      expect(filter(getUsers), isFalse);
    });

    test('RequestUrlFilter is a trimmed, case-insensitive contains', () {
      expect(const RequestUrlFilter(' users ').requestFilter(getUsers), isTrue);
      expect(
          const RequestUrlFilter('EXAMPLE').requestFilter(postOrders), isTrue);
      expect(
          const RequestUrlFilter('users').requestFilter(postOrders), isFalse);
      expect(const RequestUrlFilter('').requestFilter(postOrders), isTrue);
    });

    test('RequestStatusCodeFilter matches the exact status code', () {
      final filter = const RequestStatusCodeFilter(500).requestFilter;

      expect(filter(postOrders), isTrue);
      expect(filter(getUsers), isFalse);
      expect(filter(sampleRequest(statusCode: null)), isFalse);
    });
  });

  group('RequestStopperFilter', () {
    test('without criteria it stops every request', () {
      const filter = RequestStopperFilter();

      expect(filter.shouldStop(getUsers), isTrue);
      expect(filter.shouldStop(postOrders), isTrue);
    });

    test('checks the method and the URL pattern', () {
      const filter = RequestStopperFilter(
        requestMethod: RequestMethod.GET,
        urlPattern: ' USERS ',
      );

      expect(filter.shouldStop(getUsers), isTrue);
      expect(filter.shouldStop(postOrders), isFalse);
      expect(
        filter.shouldStop(sampleRequest(
          requestMethod: RequestMethod.GET,
          url: 'https://api.example.com/orders',
        )),
        isFalse,
      );
    });

    test('ignores a blank URL pattern', () {
      const filter = RequestStopperFilter(urlPattern: '   ');

      expect(filter.shouldStop(postOrders), isTrue);
    });

    test('never stops something that is not a RequestDetails', () {
      const filter = RequestStopperFilter();

      expect(
        filter.shouldStop(const ResponseDetails(statusCode: 200, url: 'u')),
        isFalse,
      );
    });
  });

  group('ResponseStopperFilter', () {
    const notFound = ResponseDetails(
      statusCode: 404,
      url: 'https://api.example.com/Users/1',
    );
    const ok = ResponseDetails(
      statusCode: 200,
      url: 'https://api.example.com/orders',
    );

    test('without criteria it stops every response', () {
      const filter = ResponseStopperFilter();

      expect(filter.shouldStop(notFound), isTrue);
      expect(filter.shouldStop(ok), isTrue);
    });

    test('checks the status code and the URL pattern', () {
      expect(
        const ResponseStopperFilter(statusCode: 404).shouldStop(notFound),
        isTrue,
      );
      expect(
          const ResponseStopperFilter(statusCode: 404).shouldStop(ok), isFalse);
      expect(
        const ResponseStopperFilter(urlPattern: 'users').shouldStop(notFound),
        isTrue,
      );
      expect(
        const ResponseStopperFilter(statusCode: 404, urlPattern: 'orders')
            .shouldStop(notFound),
        isFalse,
      );
      expect(
        const ResponseStopperFilter(urlPattern: ' ').shouldStop(ok),
        isTrue,
      );
    });

    test('never stops something that is not a ResponseDetails', () {
      expect(const ResponseStopperFilter().shouldStop(getUsers), isFalse);
    });
  });
}
