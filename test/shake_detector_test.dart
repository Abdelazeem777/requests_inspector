import 'package:flutter_test/flutter_test.dart';
import 'package:requests_inspector/src/shake.dart';

import 'helpers/plugin_mocks.dart';

void main() {
  late ShakeDetector detector;
  late int shakes;

  /// Pretends the previous shake happened [ago], since the detector
  /// throttles on the wall clock.
  void lastShake(Duration ago) => detector.mShakeTimestamp = DateTime.now()
      .subtract(ago)
      .millisecondsSinceEpoch;

  Future<void> shake({double gForce = 3}) async {
    FakeSensors.emit(gForce: gForce);
    await pumpEventQueue();
  }

  Future<void> start({int minimumShakeCount = 1}) async {
    shakes = 0;
    detector = ShakeDetector.autoStart(
      onPhoneShake: () => shakes++,
      minimumShakeCount: minimumShakeCount,
    );
    await pumpEventQueue();
    expect(FakeSensors.isListening, isTrue);
  }

  tearDown(() async {
    detector.stopListening();
    await pumpEventQueue();
  });

  test('triggers on a strong enough movement', () async {
    await start();
    lastShake(const Duration(seconds: 1));

    await shake();

    expect(shakes, 1);
  });

  test('ignores readings below the threshold', () async {
    await start();
    lastShake(const Duration(seconds: 1));

    await shake(gForce: 1);
    await shake(gForce: 2.5);

    expect(shakes, 0);
  });

  test('ignores shakes closer than shakeSlopTimeMS', () async {
    await start();
    lastShake(const Duration(milliseconds: 100));

    await shake();

    expect(shakes, 0);
  });

  test('needs minimumShakeCount shakes in a row', () async {
    await start(minimumShakeCount: 3);

    for (var i = 0; i < 2; i++) {
      lastShake(const Duration(milliseconds: 600));
      await shake();
    }
    expect(shakes, 0);

    lastShake(const Duration(milliseconds: 600));
    await shake();
    expect(shakes, 1);
  });

  test('resets the count after shakeCountResetTime', () async {
    await start(minimumShakeCount: 2);
    lastShake(const Duration(milliseconds: 600));
    await shake();

    lastShake(const Duration(seconds: 4));
    await shake();

    expect(shakes, 0, reason: 'the first shake expired');
    expect(detector.mShakeCount, 1);
  });

  test('stopListening cancels the accelerometer subscription', () async {
    await start();

    detector.stopListening();
    await pumpEventQueue();

    expect(FakeSensors.isListening, isFalse);
  });
}
