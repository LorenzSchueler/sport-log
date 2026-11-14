import 'package:jni/jni.dart';
import 'package:jni_flutter/jni_flutter.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/helpers/platform/android.g.dart';

/// Turns the screen off while the proximity sensor is covered (Android only).
class ProximityWakeLock {
  static final PowerManager$WakeLock? _wakeLock = _newWakeLock();

  static PowerManager$WakeLock? _newWakeLock() {
    final powerManager = androidApplicationContext
        .as(Context.type)
        .getSystemService<PowerManager>(PowerManager.type.jClass)!;
    if (!powerManager.isWakeLockLevelSupported(
      PowerManager.PROXIMITY_SCREEN_OFF_WAKE_LOCK,
    )) {
      return null;
    }
    return powerManager.newWakeLock(
      PowerManager.PROXIMITY_SCREEN_OFF_WAKE_LOCK,
      "sport_log:proximity".toJString(),
    )!..referenceCounted = false;
  }

  static void acquire() {
    if (Config.isAndroid) {
      _wakeLock?.acquire();
    }
  }

  static void release() {
    if (Config.isAndroid && (_wakeLock?.isHeld ?? false)) {
      _wakeLock!.release$1();
    }
  }
}
