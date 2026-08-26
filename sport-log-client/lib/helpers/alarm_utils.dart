import 'package:sport_log/helpers/tracking_utils.dart';
import 'package:sport_log/helpers/tts_utils.dart';
import 'package:sport_log/models/all.dart';

class AlarmUtils {
  AlarmUtils(this._routeAlarmDistance, this._routeTrack);

  late final List<Position> Function() _getSessionTrack;
  late final TrackingMode Function() _getTrackingMode;

  final int? _routeAlarmDistance;
  final List<Position>? _routeTrack;
  bool _movingWhenPausedAlarmFired = false;
  DateTime? _lastAlarm;

  bool get _routeAlarmEnabled =>
      _routeAlarmDistance != null && _routeTrack != null;

  bool get noTts => _routeAlarmEnabled && !TtsUtils.ttsEngineFound;

  static const _movingWhenPausedAlarmDistance = 50;
  static const _minAlarmInterval = Duration(minutes: 1);

  void setCallbacks(
    List<Position> Function() getSessionTrack,
    TrackingMode Function() getTrackingMode,
  ) {
    _getSessionTrack = getSessionTrack;
    _getTrackingMode = getTrackingMode;
  }

  Future<void> onNewPosition(Position position) async {
    await _movingWhenPausedAlarm(position);
    await _routeAlarm(position);
  }

  Future<void> _movingWhenPausedAlarm(Position position) async {
    if (!_getTrackingMode().isPaused) {
      _movingWhenPausedAlarmFired = false;
      return;
    }
    final lastPosition = _getSessionTrack().lastOrNull;
    if (!_movingWhenPausedAlarmFired && lastPosition != null) {
      final distance = position.distanceTo(lastPosition);
      if (distance > _movingWhenPausedAlarmDistance) {
        _movingWhenPausedAlarmFired = true;
        await TtsUtils.speak(
          "You are more than $_movingWhenPausedAlarmDistance meters from the position where you paused recording. You may want to resume recording.",
        );
      }
    }
  }

  Future<void> _routeAlarm(Position position) async {
    if (_routeAlarmDistance != null &&
        _routeTrack != null &&
        _getTrackingMode().isTracking &&
        (_lastAlarm?.isBefore(DateTime.now().subtract(_minAlarmInterval)) ??
            true)) {
      final (distance, index) = position.minDistanceTo(_routeTrack);
      if (distance > _routeAlarmDistance && index != null) {
        _lastAlarm = DateTime.now();
        await TtsUtils.speak(
          "You are off route by ${distance.round()} meters.",
        );
      }
    }
  }
}
