import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sport_log/app.dart';

class StepCountUtils {
  void Function(StepCount stepCount) onStepCountUpdate;

  StreamSubscription? _stepCountSubscription;
  late StepCount _lastStepCount;

  StepCountUtils(this.onStepCountUpdate);

  Future<bool> startStepCountStream() async {
    while (!await Permission.activityRecognition.request().isGranted) {
      final ignore = await showDialog<bool>(
        context: AppState.globalContext,
        builder: (context) => AlertDialog(
          content: const Text(
            "In order to record your steps 'Activity Recognition' must be allowed.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ignore'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Change Permission'),
            )
          ],
        ),
      );
      if (ignore == null || ignore) {
        return false;
      }
    }
    Stream<StepCount> _stepCountStream = Pedometer.stepCountStream;
    _stepCountSubscription = _stepCountStream.listen((stepcount) {
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
