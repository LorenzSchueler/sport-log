import 'package:flutter/material.dart';

enum TrackingMode { notStarted, tracking, paused }

class TrackingUtils extends ChangeNotifier {
  TrackingMode _trackingMode = TrackingMode.notStarted;
  late DateTime _lastResumeTime;
  Duration _lastStopDuration = Duration.zero;

  void start() {
    _trackingMode = TrackingMode.tracking;
    _lastResumeTime = DateTime.now();
    notifyListeners();
  }

  void resume() {
    _trackingMode = TrackingMode.tracking;
    _lastResumeTime = DateTime.now();
    notifyListeners();
  }

  void pause() {
    _trackingMode = TrackingMode.paused;
    _lastStopDuration += DateTime.now().difference(_lastResumeTime);
    notifyListeners();
  }

  TrackingMode get mode => _trackingMode;

  bool get isTracking => _trackingMode == TrackingMode.tracking;

  Duration get currentDuration => isTracking
      ? _lastStopDuration + DateTime.now().difference(_lastResumeTime)
      : _lastStopDuration;
}
