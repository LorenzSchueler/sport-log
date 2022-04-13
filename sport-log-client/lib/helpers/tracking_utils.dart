enum TrackingMode { notStarted, tracking, paused }

class TrackingUtils {
  TrackingMode _trackingMode = TrackingMode.notStarted;
  late DateTime _lastResumeTime;
  Duration _lastStopDuration = Duration.zero;

  void start() {
    _trackingMode = TrackingMode.tracking;
    _lastResumeTime = DateTime.now();
  }

  void resume() {
    _trackingMode = TrackingMode.tracking;
    _lastResumeTime = DateTime.now();
  }

  void pause() {
    _trackingMode = TrackingMode.paused;
    _lastStopDuration += DateTime.now().difference(_lastResumeTime);
  }

  TrackingMode get mode => _trackingMode;

  bool get isTracking => _trackingMode == TrackingMode.tracking;

  Duration get currentDuration => _trackingMode == TrackingMode.tracking
      ? _lastStopDuration + DateTime.now().difference(_lastResumeTime)
      : _lastStopDuration;
}
