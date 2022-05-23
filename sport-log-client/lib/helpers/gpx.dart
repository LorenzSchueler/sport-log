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
  List<Position> track = [];
  for (final point in points) {
    track.add(
      Position(
        longitude: point.lon ?? 0.0,
        latitude: point.lat ?? 0.0,
        elevation: point.ele?.toDouble() ?? 0.0,
        distance: track.isEmpty
            ? 0
            : track.last.addDistanceTo(point.lat ?? 0.0, point.lon ?? 0.0),
        time: startTime == null || point.time == null
            ? Duration.zero
            : point.time!.difference(startTime),
      ),
    );
  }
  return track;
}

String trackToGpx(List<Position> track, {DateTime? startTime}) {
  final points = track
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
