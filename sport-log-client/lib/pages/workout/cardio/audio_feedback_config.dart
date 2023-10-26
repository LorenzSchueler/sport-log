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

extension on int {
  String toSpeech() {
    var text = "";
    if (this >= 1000) {
      text += "${this ~/ 1000} thousand ";
    }
    if (this == 0 || (this % 1000) > 0) {
      text += "${this % 1000} ";
    }

    return text;
  }
}

enum IntervalType { distance, time }

class AudioFeedbackConfig extends ChangeNotifier {
  factory AudioFeedbackConfig() {
    final audioFeedback = AudioFeedbackConfig._();
    for (final metric in audioFeedback.metrics) {
      metric.addListener(audioFeedback.notifyListeners);
    }
    return audioFeedback;
  }

  AudioFeedbackConfig._();

  @override
  void dispose() {
    for (final metric in metrics) {
      metric.dispose();
    }
    super.dispose();
  }

  IntervalType _intervalType = IntervalType.distance;
  IntervalType get intervalType => _intervalType;
  set intervalType(IntervalType intervalType) {
    _intervalType = intervalType;
    interval = _intervalType == IntervalType.distance ? 1000 : 60;
    notifyListeners();
  }

  // meter/ seconds
  int _interval = 1000;
  int get interval => _interval;
  set interval(int interval) {
    _interval = interval;
    notifyListeners();
  }

  List<AudioFeedbackMetric> metrics = [
    AudioFeedbackMetric.enabled(
      "Distance",
      (c) {
        final track = c.track;
        if (track == null) {
          return null;
        }
        return (track.last.distance / 1000).toStringMaxFixed(1);
      },
      "kilometers",
    ),
    AudioFeedbackMetric.enabled(
      "Duration",
      (c) => c.track?.last.time.toSpeech(),
      "",
    ),
    AudioFeedbackMetric.enabled(
      "Average Speed",
      (c) => c.speed?.toStringAsFixed(1),
      "kilometers per hour",
    ),
    AudioFeedbackMetric.enabled(
      "Current Speed",
      (c) {
        final track = c.track;
        if (track == null) {
          return null;
        }
        final end = track.last.time;
        final start = end - TrackingUtils.currentDurationOffset;
        return c.currentSpeed(start, end)?.toStringAsFixed(1);
      },
      "kilometers per hour",
    ),
    AudioFeedbackMetric.disabled(
      "Average Tempo",
      (c) => c.tempo?.toSpeech(),
      "per kilometer",
    ),
    AudioFeedbackMetric.disabled(
      "Current Tempo",
      (c) {
        final track = c.track;
        if (track == null) {
          return null;
        }
        final end = track.last.time;
        final start = end - TrackingUtils.currentDurationOffset;
        return c.currentTempo(start, end)?.toSpeech();
      },
      "per kilometer",
    ),
    AudioFeedbackMetric.disabled(
      "Average Cadence",
      (c) => c.avgCadence?.toSpeech(),
      "rounds per minute",
    ),
    AudioFeedbackMetric.disabled(
      "Current Cadence",
      (c) {
        final track = c.track;
        if (track == null) {
          return null;
        }
        final end = track.last.time;
        final start = end - TrackingUtils.currentDurationOffset;
        return c.currentCadence(start, end)?.toSpeech();
      },
      "rounds per minute",
    ),
    AudioFeedbackMetric.disabled(
      "Average Heart Rate",
      (c) => c.avgHeartRate?.toSpeech(),
      "beats per minute",
    ),
    AudioFeedbackMetric.disabled(
      "Current Heart Rate",
      (c) {
        final track = c.track;
        if (track == null) {
          return null;
        }
        final end = track.last.time;
        final start = end - TrackingUtils.currentDurationOffset;
        return c.currentHeartRate(start, end)?.toSpeech();
      },
      "beats per minute",
    ),
    AudioFeedbackMetric.disabled(
      "Elevation",
      (c) => c.track?.last.elevation.round().toSpeech(),
      "meters",
    ),
    AudioFeedbackMetric.disabled(
      "Ascent",
      (c) => c.ascent?.toSpeech(),
      "meters",
    ),
    AudioFeedbackMetric.disabled(
      "Descent",
      (c) => c.descent?.toSpeech(),
      "meters",
    ),
  ];
}

class AudioFeedbackMetric extends ChangeNotifier {
  AudioFeedbackMetric.enabled(this.name, this._value, this._unit)
      : _isEnabled = true;
  AudioFeedbackMetric.disabled(this.name, this._value, this._unit)
      : _isEnabled = false;

  final String name;
  final String? Function(CardioSession) _value;
  final String _unit;

  String? text(CardioSession session) {
    if (!_isEnabled) {
      return null;
    }
    final v = _value(session);
    return v != null ? "$name: $v $_unit" : null;
  }

  bool _isEnabled;
  bool get isEnabled => _isEnabled;
  set isEnabled(bool isEnabled) {
    _isEnabled = isEnabled;
    notifyListeners();
  }
}
