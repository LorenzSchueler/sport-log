import 'dart:async';

import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sport_log/widgets/dialogs/system_settings_dialog.dart';

class StepCountUtils {
  StepCountUtils(this.onStepCountUpdate);

  void Function(StepCount stepCount) onStepCountUpdate;
  StreamSubscription? _stepCountSubscription;
  late StepCount _lastStepCount;

  Future<bool> startStepCountStream() async {
    while (!await Permission.activityRecognition.request().isGranted) {
      final ignore = await showSystemSettingsDialog(
        text:
            "In order to record your steps 'Activity Recognition' must be allowed.",
      );
      if (ignore) {
        return false;
      }
    }
    Stream<StepCount> stepCountStream = Pedometer.stepCountStream;
    _stepCountSubscription = stepCountStream.listen((stepcount) {
      onStepCountUpdate(stepcount);
      _lastStepCount = stepcount;
    });

    return true;
  }

  void stopStepCountStream() {
    _stepCountSubscription?.cancel();
    _stepCountSubscription = null;
  }

  bool get enabled => _stepCountSubscription != null;

  StepCount get lastStepCount => _lastStepCount;
}
