import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_log/models/cardio/cardio_session.dart';
import 'package:sport_log/models/cardio/position.dart';
import 'package:sport_log/models/cardio/route.dart';

Position _pos(double elevation) => Position(
  longitude: 0,
  latitude: 0,
  elevation: elevation,
  distance: 0,
  time: Duration.zero,
);

List<Position> _track(List<double> elevations) => elevations.map(_pos).toList();

void main() {
  group("noiseFilteredAscentDescent", () {
    final cases = {
      "empty track": (<double>[], (0, 0)),
      "single position": ([100.0], (0, 0)),
      "noise below threshold is ignored": (
        [100.0, 104.0, 98.0, 103.0, 100.0],
        (0, 0),
      ),
      "climb above threshold counts": ([100.0, 130.0], (30, 0)),
      "descent above threshold counts": ([130.0, 100.0], (0, 30)),
      "noise on top of a climb is ignored": (
        [100.0, 103.0, 130.0, 127.0, 135.0, 110.0],
        (30, 20),
      ),
    };

    for (final MapEntry(key: name, value: (elevations, expected))
        in cases.entries) {
      test(
        name,
        () => expect(_track(elevations).noiseFilteredAscentDescent(), expected),
      );
    }
  });

  test("route and cardio session agree on ascent and descent", () {
    final elevations = [100.0, 103.0, 130.0, 127.0, 160.0, 158.0, 120.0];

    final route = Route.defaultValue()..track = _track(elevations);
    final session = CardioSession.defaultValue(Int64(1))
      ..track = _track(elevations);
    route.setAscentDescent();
    session.setAscentDescent();

    expect((route.ascent, route.descent), (session.ascent, session.descent));
    expect((route.ascent, route.descent), (60, 40));
  });
}
