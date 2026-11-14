import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

TestDefaultBinaryMessenger get _messenger =>
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

/// Fake platform side of `sensors_plus`.
///
/// `InspectorController` starts a `ShakeDetector` whenever it is created with
/// shaking enabled, and the host platform used by `flutter test` has no
/// sensors_plus implementation (-> `MissingPluginException`). This fake
/// answers the method channel and lets tests push accelerometer readings.
class FakeSensors {
  FakeSensors._();

  static const methodChannel =
      MethodChannel('dev.fluttercommunity.plus/sensors/method');
  static const accelerometerChannel =
      EventChannel('dev.fluttercommunity.plus/sensors/accelerometer');

  static MockStreamHandlerEventSink? _sink;

  /// Whether something is currently subscribed to the accelerometer stream.
  static bool get isListening => _sink != null;

  static void install() {
    _messenger.setMockMethodCallHandler(methodChannel, (_) async => null);
    _messenger.setMockStreamHandler(
      accelerometerChannel,
      // Block bodies: an arrow would return the sink as the call's result.
      MockStreamHandler.inline(
        onListen: (_, sink) {
          _sink = sink;
        },
        onCancel: (_) {
          _sink = null;
        },
      ),
    );
  }

  /// Emits one accelerometer reading of [gForce] times gravity (x axis only).
  static void emit({double gForce = 1}) {
    _sink?.success(<double>[
      gForce * 9.80665,
      0,
      0,
      DateTime.now().microsecondsSinceEpoch.toDouble(),
    ]);
  }
}
