import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus_platform_interface/method_channel/method_channel_share.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

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

/// Records what is sent over the real `share_plus` method channel.
///
/// `flutter test` runs the Dart plugin registrant for the host, which on Linux
/// swaps in a url_launcher based implementation. [install] pins the
/// method-channel implementation so the same test passes on every host.
class FakeShareChannel {
  FakeShareChannel._();

  static final calls = <MethodCall>[];

  static void install() {
    SharePlatform.instance = MethodChannelShare();
    calls.clear();
    _messenger.setMockMethodCallHandler(MethodChannelShare.channel, (call) {
      calls.add(call);
      return Future.value('');
    });
  }

  static String? get lastSharedText =>
      calls.isEmpty ? null : (calls.last.arguments as Map)['text'] as String?;
}

/// A [SharePlatform] that records [ShareParams] instead of touching the
/// platform, so file shares can be inspected without path_provider.
class RecordingSharePlatform extends SharePlatform {
  final shared = <ShareParams>[];

  @override
  Future<ShareResult> share(ShareParams params) async {
    shared.add(params);
    return const ShareResult('', ShareResultStatus.success);
  }
}

/// Captures `Clipboard.setData` calls.
class FakeClipboard {
  FakeClipboard._();

  static String? text;

  static void install() {
    text = null;
    _messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        text = (call.arguments as Map)['text'] as String?;
      }
      return null;
    });
  }
}
