/// Replacement for [Stopwatch] because it ticks to slow when not in foreground (https://github.com/flutter/flutter/issues/44719).
class StopwatchX {
  bool _isRunning = false;
  DateTime _lastResumeTime = DateTime.now(); // gets overwritten anyway
  Duration _lastStopDuration = Duration.zero;

  Duration get elapsed =>
      _isRunning
          ? _lastStopDuration + DateTime.now().difference(_lastResumeTime)
          : _lastStopDuration;

  void start() {
    _isRunning = true;
    _lastResumeTime = DateTime.now();
  }

  void stop() {
    _isRunning = false;
    _lastStopDuration += DateTime.now().difference(_lastResumeTime);
  }
}
