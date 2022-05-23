import 'package:collection/collection.dart';
import 'package:gpx/gpx.dart';
import 'package:sport_log/models/cardio/position.dart';

List<Position> gpxToTrack(String gpxString) {
  final gpx = GpxReader().fromString(gpxString);
  final points =
      gpx.trks.map((t) => t.trksegs).flattened.map((t) => t.trkpts).flattened;
  final startTime = points
      .map((p) => p.time)
      .firstWhere((element) => element != null, orElse: () => null);
  // ignore: prefer-immediate-return
  final positions = points
      .map(
        (p) => Position(
          longitude: p.lon ?? 0.0,
          latitude: p.lat ?? 0.0,
          elevation: p.ele?.toDouble() ?? 0.0,
          distance: 0.0,
          time: startTime == null || p.time == null
              ? Duration.zero
              : p.time!.difference(startTime),
        ),
      )
      .toList();
  return positions;
}

String trackToGpx(List<Position> positions, {DateTime? startTime}) {
  final points = positions
      .map(
        (p) => Wpt(
          lon: p.longitude,
          lat: p.latitude,
          ele: p.elevation,
          time: startTime?.add(p.time),
        ),
      )
      .toList();
  final gpx = Gpx()
    ..creator = "Sport-Log-Client"
    ..trks.add(Trk(trksegs: [Trkseg(trkpts: points)]));
  return GpxWriter().asString(gpx);
}
