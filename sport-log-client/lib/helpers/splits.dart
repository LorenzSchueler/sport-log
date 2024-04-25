import 'package:sport_log/models/cardio/position.dart';

class Split {
  factory Split._compute({
    required int startDistance,
    required int endDistance,
    required Duration startDuration,
    required Duration endDuration,
  }) {
    final distance = endDistance - startDistance;
    final duration = endDuration - startDuration;
    final speed = ((endDistance - startDistance) / 1000) /
        (duration.inMilliseconds / 1000 / 3600);
    final tempo = Duration(
      milliseconds:
          (duration.inMilliseconds / ((endDistance - startDistance) / 1000))
              .round(),
    );
    return Split._(
      startDistance: startDistance,
      endDistance: endDistance,
      startDuration: startDuration,
      endDuration: endDuration,
      distance: distance,
      duration: duration,
      speed: speed,
      tempo: tempo,
    );
  }

  Split._({
    required this.startDistance,
    required this.endDistance,
    required this.startDuration,
    required this.endDuration,
    required this.distance,
    required this.duration,
    required this.speed,
    required this.tempo,
  });

  static List<Split> computeAll(List<Position>? track) {
    if (track == null || track.isEmpty) {
      return [];
    }

    const splitDistance = 1000; // m
    final splits = <Split>[];
    var lastDistance = 0;
    var lastTime = Duration.zero;

    for (var i = 0; i < track.length - 1; i++) {
      if ((track[i].distance / splitDistance).floor() <
          (track[i + 1].distance / splitDistance).floor()) {
        final pos1 = track[i];
        final pos2 = track[i + 1];
        final newDistance =
            (pos2.distance / splitDistance).floor() * splitDistance;
        final distanceDiff = pos2.distance - pos1.distance;
        final weight1 = (newDistance - pos1.distance) / distanceDiff;
        final weight2 = (pos2.distance - newDistance) / distanceDiff;
        final newTime = pos1.time * weight1 + pos2.time * weight2;

        splits.add(
          Split._compute(
            startDistance: lastDistance,
            endDistance: newDistance,
            startDuration: lastTime,
            endDuration: newTime,
          ),
        );
        lastDistance = newDistance;
        lastTime = newTime;
      }
    }
    splits.add(
      Split._compute(
        startDistance: lastDistance,
        endDistance: track[track.length - 1].distance.round(),
        startDuration: lastTime,
        endDuration: track[track.length - 1].time,
      ),
    );

    return splits;
  }

  // distance in m
  final int startDistance;
  // distance in m
  final int endDistance;
  // distance in m
  final int distance;
  final Duration startDuration;
  final Duration endDuration;
  final Duration duration;
  // speed in km/h
  final double speed;
  // tempo per km
  final Duration tempo;
}
