import 'package:flutter_test/flutter_test.dart';
import 'package:sport_log/helpers/gpx.dart';

String _gpx(String trackPoints) =>
    '<?xml version="1.0"?><gpx version="1.1" creator="test"><trk><trkseg>'
    '$trackPoints'
    '</trkseg></trk></gpx>';

void main() {
  group("gpxToTrack", () {
    final valid = {
      "with elevation": (
        trackPoint: '<trkpt lat="47.1" lon="11.2"><ele>600</ele></trkpt>',
        lat: 47.1,
        lon: 11.2,
        ele: 600.0,
      ),
      "without elevation": (
        trackPoint: '<trkpt lat="47.1" lon="11.2"></trkpt>',
        lat: 47.1,
        lon: 11.2,
        ele: 0.0,
      ),
    };

    for (final MapEntry(key: name, value: (:trackPoint, :lat, :lon, :ele))
        in valid.entries) {
      test("reads valid track points $name", () {
        final track = gpxToTrack(_gpx(trackPoint));
        expect(track.isOk, true);
        expect(track.ok.length, 1);
        expect(track.ok.first.latitude, lat);
        expect(track.ok.first.longitude, lon);
        expect(track.ok.first.elevation, ele);
      });
    }

    final invalid = {
      "not a number": '<trkpt lat="NaN" lon="11.2"></trkpt>',
      "infinite": '<trkpt lat="Infinity" lon="11.2"></trkpt>',
      "latitude out of range": '<trkpt lat="91" lon="11.2"></trkpt>',
      "longitude out of range": '<trkpt lat="47.1" lon="181"></trkpt>',
      "without coordinates": "<trkpt></trkpt>",
      "without a finite elevation":
          '<trkpt lat="47.1" lon="11.2"><ele>NaN</ele></trkpt>',
    };

    for (final MapEntry(key: name, value: trackPoint) in invalid.entries) {
      test("rejects a track of only points that are $name", () {
        expect(gpxToTrack(_gpx(trackPoint)).isErr, true);
      });
    }

    test("skips invalid points but keeps valid ones", () {
      final track = gpxToTrack(
        _gpx(
          '<trkpt lat="47.1" lon="11.2"></trkpt>'
          '<trkpt lat="NaN" lon="11.2"></trkpt>'
          '<trkpt lat="47.2" lon="11.3"></trkpt>',
        ),
      );
      expect(track.isOk, true);
      expect(track.ok.length, 2);
      expect(track.ok.every((p) => p.distance.isFinite), true);
    });
  });
}
