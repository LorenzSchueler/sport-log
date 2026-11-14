import 'package:jni_flutter/jni_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/helpers/platform/android.g.dart';
import 'package:sport_log/helpers/request_permission.dart';

class StepCountUtils {
  SensorEventListener? _stepListener;

  static final _sensorManager = androidApplicationContext
      .as(Context.type)
      .getSystemService<SensorManager>(SensorManager.type.jClass)!;

  bool get enabled => _stepListener != null;

  void dispose() {
    if (_stepListener != null) {
      _sensorManager.unregisterListener(_stepListener);
      _stepListener?.release();
      _stepListener = null;
    }
  }

  Future<bool> startStepStream(void Function() onStep) async {
    if (_stepListener != null) {
      return false;
    }
    final sensor = Config.isAndroid
        ? _sensorManager.getDefaultSensor(Sensor.TYPE_STEP_DETECTOR)
        : null;
    if (sensor == null) {
      return false;
    }
    if (!await PermissionRequest.request(Permission.activityRecognition)) {
      sensor.release();
      return false;
    }
    final listener = SensorEventListener.implement(
      $SensorEventListener(
        onSensorChanged: (_) => onStep(),
        onSensorChanged$async: true,
        onAccuracyChanged: (_, _) {},
        onAccuracyChanged$async: true,
      ),
    );
    final registered = _sensorManager.registerListener(
      listener,
      sensor,
      SensorManager.SENSOR_DELAY_FASTEST,
    );
    sensor.release();
    if (!registered) {
      listener.release();
      return false;
    }
    _stepListener = listener;

    return true;
  }
}
