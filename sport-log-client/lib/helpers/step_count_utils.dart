import 'dart:async';

import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sport_log/widgets/dialogs/dialogs.dart';

class StepCountUtils {
  StreamSubscription<StepCount>? _stepCountSubscription;
  StepCount? _lastStepCount;

  void dispose() {
    stopStepCountStream();
  }

  Future<bool> startStepCountStream(
    void Function(StepCount stepCount) onStepCountUpdate,
  ) async {
    if (_stepCountSubscription != null) {
      return false;
    }
    while (!await Permission.activityRecognition.request().isGranted) {
      final systemSettings = await showSystemSettingsDialog(
        text:
            "In order to record your steps 'Activity Recognition' must be allowed.",
      );
      if (systemSettings.isIgnore) {
        return false;
      }
    }
    _stepCountSubscription = Pedometer.stepCountStream.listen((stepCount) {
      onStepCountUpdate(stepCount);
      _lastStepCount = stepCount;
    });

    return true;
  }

  Future<void> stopStepCountStream() async {
    await _stepCountSubscription?.cancel();
    _stepCountSubscription = null;
  }

  bool get enabled => _stepCountSubscription != null;

  StepCount? get lastStepCount => _lastStepCount;
}
