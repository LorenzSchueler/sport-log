import 'dart:async';

import 'package:sport_log/helpers/tracking_utils.dart';
import 'package:sport_log/helpers/tts_utils.dart';
import 'package:sport_log/models/cardio/cardio_session.dart';
import 'package:sport_log/pages/workout/cardio/audio_feedback_config.dart';

class AudioFeedbackUtils {
  AudioFeedbackUtils(this._audioFeedbackConfig);

  late final CardioSession Function() _getCardioSession;
  late final TrackingMode Function() _getTrackingMode;
  final AudioFeedbackConfig? _audioFeedbackConfig;
  Timer? _audioFeedbackTimer;

  bool get noTts => _audioFeedbackConfig != null && !TtsUtils.ttsEngineFound;

  void setCallbacks(
    CardioSession Function() getCardioSession,
    TrackingMode Function() getTrackingMode,
  ) {
    _getCardioSession = getCardioSession;
    _getTrackingMode = getTrackingMode;
  }

  void dispose() {
    onStop();
  }

  void onStop() {
    _audioFeedbackTimer?.cancel();
  }

  void onStart() {
    if (_audioFeedbackConfig != null &&
        _audioFeedbackConfig.intervalType.isTime) {
      _audioFeedbackTimer = Timer.periodic(
        Duration(seconds: _audioFeedbackConfig.interval),
        (_) => _onTimer(),
      );
    }
  }

  Future<void> _onTimer() async {
    final config = _audioFeedbackConfig;
    final session = _getCardioSession();
    if (config != null &&
        config.intervalType.isTime &&
        _getTrackingMode().isTracking) {
      await _audioFeedback(config, session);
    }
  }

  Future<void> onNewPosition() async {
    final config = _audioFeedbackConfig;
    final session = _getCardioSession();
    final track = session.track!;
    if (config != null &&
        config.intervalType.isDistance &&
        _getTrackingMode().isTracking &&
        track.length >= 2) {
      final prevLap = track[track.length - 2].distance ~/ config.interval;
      final currLap = track.last.distance ~/ config.interval;
      if (prevLap < currLap) {
        await _audioFeedback(config, session);
      }
    }
  }

  Future<void> _audioFeedback(
    AudioFeedbackConfig config,
    CardioSession session,
  ) => TtsUtils.speak(config.text(session));
}
