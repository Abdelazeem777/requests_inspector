import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'helpers/plugin_mocks.dart';

/// Picked up automatically by `flutter test` for every test in this folder.
///
/// `InspectorController` is a singleton that starts listening to the
/// accelerometer (sensors_plus) as soon as it is created with shaking
/// enabled, so every test gets a fake sensors_plus platform side.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(FakeSensors.install);
  await testMain();
}
