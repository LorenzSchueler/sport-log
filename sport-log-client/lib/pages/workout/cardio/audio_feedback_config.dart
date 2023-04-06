import 'package:flutter/material.dart';
import 'package:sport_log/helpers/extensions/double_extension.dart';
import 'package:sport_log/helpers/tracking_utils.dart';
import 'package:sport_log/models/cardio/cardio_session.dart';

extension on Duration {
  /// 2 hours 20 minutes and 30 seconds
  /// 1 hour 20 minutes and 30 seconds
  /// 20 minutes and 30 seconds
  /// 0 minutes and 30 seconds
  String toSpeech() {
    var text = "";
    if (inHours == 1) {
      text += "1 hour ";
    } else if (inHours > 1) {
      text += "$inHours hours ";
    }
    text += "${inMinutes - inHours * 60} minutes and ";
    text += "${inSeconds - inMinutes * 60 - inHours * 60 * 60} seconds";

    return text;
  }
}

class AudioFeedbackConfig extends ChangeNotifier {
  factory AudioFeedbackConfig() {
    final audioFeedback = AudioFeedbackConfig._();
    audioFeedback.distance.addListener(audioFeedback.notifyListeners);
    audioFeedback.duration.addListener(audioFeedback.notifyListeners);
    audioFeedback.elevation.addListener(audioFeedback.notifyListeners);
    audioFeedback.avgSpeed.addListener(audioFeedback.notifyListeners);
    audioFeedback.currentSpeed.addListener(audioFeedback.notifyListeners);
    audioFeedback.avgTempo.addListener(audioFeedback.notifyListeners);
    audioFeedback.currentTempo.addListener(audioFeedback.notifyListeners);
    return audioFeedback;
  }

  AudioFeedbackConfig._()
      : _interval = 1000,
        distance = AudioFeedbackMetric.enabled(
          "Distance",
          (c) =>
              "${(c.track!.last.distance / 1000).toStringMaxFixed(1)} kilometers",
        ),
        duration = AudioFeedbackMetric.enabled(
          "Duration",
          (c) => c.track!.last.time.toSpeech(),
        ),
        elevation = AudioFeedbackMetric.disabled(
          "Elevation",
          (c) => "${c.track!.last.elevation.round()} meters",
        ),
        avgSpeed = AudioFeedbackMetric.enabled(
          "Average Speed",
          (c) => "${c.speed!.toStringAsFixed(1)} kilometers per hour",
        ),
        currentSpeed = AudioFeedbackMetric.enabled(
          "Current Speed",
          (c) {
            final end = c.track!.last.time;
            final start = end - TrackingUtils.currentDurationOffset;
            return "${c.currentSpeed(start, end)!.toStringAsFixed(1)} kilometers per hour";
          },
        ),
        avgTempo = AudioFeedbackMetric.disabled(
          "Average Tempo",
          (c) => "${c.tempo!.toSpeech()} per kilometer",
        ),
        currentTempo = AudioFeedbackMetric.disabled("Current Tempo", (c) {
          final end = c.track!.last.time;
          final start = end - TrackingUtils.currentDurationOffset;
          return "${c.currentTempo(start, end)!.toSpeech()} per kilometer";
        });

  int _interval;
  int get interval => _interval;
  set interval(int interval) {
    _interval = interval;
    notifyListeners();
  }

  final AudioFeedbackMetric distance;
  final AudioFeedbackMetric duration;
  final AudioFeedbackMetric elevation;
  final AudioFeedbackMetric avgSpeed;
  final AudioFeedbackMetric currentSpeed;
  final AudioFeedbackMetric avgTempo;
  final AudioFeedbackMetric currentTempo;

  List<AudioFeedbackMetric> get metrics => [
        distance,
        time,
        elevation,
        avgSpeed,
        currentSpeed,
        avgTempo,
        currentTempo,
      ];
}

class AudioFeedbackMetric extends ChangeNotifier {
  AudioFeedbackMetric.enabled(this.name, this.value) : _isEnabled = true;
  AudioFeedbackMetric.disabled(this.name, this.value) : _isEnabled = false;

  final String name;

  /// Returns the current value and unit as a String.
  ///
  /// Call only while tracking as it relies on values being not null.
  final String Function(CardioSession) value;

  bool _isEnabled;
  bool get isEnabled => _isEnabled;
  set isEnabled(bool isEnabled) {
    _isEnabled = isEnabled;
    notifyListeners();
  }
}
