import 'dart:io';

import 'package:jnigen/jnigen.dart';

/// Generates the Android bindings with `dart run tool/jnigen.dart`.
///
/// Needs `ANDROID_SDK_ROOT` to point to an Android SDK with platform 36.
Future<void> main() async {
  final packageRoot = Platform.script.resolve('../');

  const members = <String, Map<String, List<String>>>{
    'android.content.Context': {
      'getSystemService': ['class'],
    },
    'android.os.PowerManager': {
      'isWakeLockLevelSupported': ['i'],
      'newWakeLock': ['i', 'string'],
      'PROXIMITY_SCREEN_OFF_WAKE_LOCK': [],
    },
    r'android.os.PowerManager$WakeLock': {
      'acquire': [],
      'release': [],
      'isHeld': [],
      'setReferenceCounted': ['z'],
    },
    'android.hardware.Sensor': {'TYPE_STEP_DETECTOR': []},
    'android.hardware.SensorManager': {
      'getDefaultSensor': ['i'],
      'registerListener': ['sensorEventListener', 'sensor', 'i'],
      'unregisterListener': ['sensorEventListener'],
      'SENSOR_DELAY_FASTEST': [],
    },
    'android.hardware.SensorEventListener': {
      'onSensorChanged': ['sensorEvent'],
      'onAccuracyChanged': ['sensor', 'i'],
    },
  };

  var classMembers = <String, List<String>>{};
  late Method method;
  var paramIndex = 0;
  final generator = JniGenerator(
    input: Input(
      // nested classes are generated with their outer class
      classes: members.keys.where((c) => !c.contains(r'$')).toList(),
      androidSdk: AndroidSdk(
        versions: [36],
        sdkRoot: Uri.directory(Platform.environment['ANDROID_SDK_ROOT']!),
      ),
    ),
    output: Output(
      dart: DartOutput(
        path: packageRoot.resolve('lib/helpers/platform/android.g.dart'),
        structure: OutputStructure.singleFile,
      ),
    ),
    visitors: [
      Visitor(
        classDecl: (c) {
          c.isIncluded = members.containsKey(c.binaryName);
          classMembers = members[c.binaryName] ?? {};
        },
        method: (m) {
          method = m;
          paramIndex = 0;
          m.isIncluded = classMembers.containsKey(m.originalName);
        },
        // parameter names are derived from their types, so they tell overloads apart
        param: (p) {
          final params = classMembers[method.originalName]!;
          if (paramIndex >= params.length ||
              params[paramIndex++] != p.originalName) {
            method.isIncluded = false;
          }
        },
        field: (f) => f.isIncluded = classMembers.containsKey(f.originalName),
      ),
    ],
  );

  await generator.generate();
}
