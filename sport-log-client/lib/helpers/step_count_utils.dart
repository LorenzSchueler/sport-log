import 'dart:async';

import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sport_log/widgets/dialogs/dialogs.dart';

class StepCountUtils {
  StreamSubscription<void>? _stepCountSubscription;

  bool get enabled => _stepCountSubscription != null;

  void dispose() {
    stopStepCountStream();
  }

  Future<bool> startStepStream(void Function() onStep) async {
    if (_stepCountSubscription != null) {
      return false;
    }
    while (!await Permission.activityRecognition.request().isGranted) {
      final systemSettings = await showSystemSettingsDialog(
        text:
            "In order to record your cadence 'Activity Recognition' must be allowed.",
      );
      if (systemSettings.isIgnore) {
        return false;
      }
    }
    _stepCountSubscription = Pedometer.stepStream.listen((_) => onStep());

    return true;
  }

  Future<void> stopStepCountStream() async {
    await _stepCountSubscription?.cancel();
    _stepCountSubscription = null;
  }
}
