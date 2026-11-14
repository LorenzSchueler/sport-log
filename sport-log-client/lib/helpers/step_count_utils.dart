import 'dart:async';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sport_log/helpers/request_permission.dart';

class StepCountUtils {
  StreamSubscription<void>? _stepCountSubscription;

  static const _channel = EventChannel('org.sport_log/step_detection');

  bool get enabled => _stepCountSubscription != null;

  void dispose() {
    stopStepCountStream();
  }

  Future<bool> startStepStream(void Function() onStep) async {
    if (_stepCountSubscription != null) {
      return false;
    }
    if (!await PermissionRequest.request(Permission.activityRecognition)) {
      return false;
    }
    _stepCountSubscription = _channel.receiveBroadcastStream().listen(
      (_) => onStep(),
      onError: (Object _) => stopStepCountStream(),
    );

    return true;
  }

  Future<void> stopStepCountStream() async {
    await _stepCountSubscription?.cancel();
    _stepCountSubscription = null;
  }
}
