class AudioFeedbackConfig {
  AudioFeedbackConfig()
      : _intervalMeter = 1000,
        distance = AudioFeedbackMetric("Distance", true),
        time = AudioFeedbackMetric("Time", true),
        elevation = AudioFeedbackMetric("Elevation", false),
        avgSpeed = AudioFeedbackMetric("Average Speed", true),
        currentSpeed = AudioFeedbackMetric("Current Speed", true),
        avgTempo = AudioFeedbackMetric("Average Tempo", false),
        currentTempo = AudioFeedbackMetric("Current Tempo", false);

  int _intervalMeter;
  double get interval => _intervalMeter / 1000.0;
  set interval(double km) => _intervalMeter = (km * 1000).round();

  AudioFeedbackMetric distance;
  AudioFeedbackMetric time;
  AudioFeedbackMetric elevation;
  AudioFeedbackMetric avgSpeed;
  AudioFeedbackMetric currentSpeed;
  AudioFeedbackMetric avgTempo;
  AudioFeedbackMetric currentTempo;

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

class AudioFeedbackMetric {
  AudioFeedbackMetric(this.name, this.isEnabled);

  final String name;
  bool isEnabled;
}
