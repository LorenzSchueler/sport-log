import 'package:flutter/material.dart';

class AudioFeedbackConfig extends ChangeNotifier {
  factory AudioFeedbackConfig() {
    final audioFeedback = AudioFeedbackConfig._();
    audioFeedback.distance.addListener(audioFeedback.notifyListeners);
    audioFeedback.time.addListener(audioFeedback.notifyListeners);
    audioFeedback.elevation.addListener(audioFeedback.notifyListeners);
    audioFeedback.avgSpeed.addListener(audioFeedback.notifyListeners);
    audioFeedback.currentSpeed.addListener(audioFeedback.notifyListeners);
    audioFeedback.avgTempo.addListener(audioFeedback.notifyListeners);
    audioFeedback.currentTempo.addListener(audioFeedback.notifyListeners);
    return audioFeedback;
  }

  AudioFeedbackConfig._()
      : _interval = 1000,
        distance = AudioFeedbackMetric.enabled("Distance"),
        time = AudioFeedbackMetric.enabled("Time"),
        elevation = AudioFeedbackMetric.disabled("Elevation"),
        avgSpeed = AudioFeedbackMetric.enabled("Average Speed"),
        currentSpeed = AudioFeedbackMetric.enabled("Current Speed"),
        avgTempo = AudioFeedbackMetric.disabled("Average Tempo"),
        currentTempo = AudioFeedbackMetric.disabled("Current Tempo");

  int _interval;
  int get interval => _interval;
  set interval(int interval) {
    _interval = interval;
    notifyListeners();
  }

  final AudioFeedbackMetric distance;
  final AudioFeedbackMetric time;
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
  AudioFeedbackMetric.enabled(this.name) : _isEnabled = true;
  AudioFeedbackMetric.disabled(this.name) : _isEnabled = false;

  final String name;

  bool _isEnabled;
  bool get isEnabled => _isEnabled;
  set isEnabled(bool isEnabled) {
    _isEnabled = isEnabled;
    notifyListeners();
  }
}
