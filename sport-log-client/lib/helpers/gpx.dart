import 'dart:io';

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:gpx/gpx.dart';
import 'package:sport_log/helpers/lat_lng.dart';
import 'package:sport_log/helpers/notification_controller.dart';
import 'package:sport_log/helpers/result.dart';
import 'package:sport_log/helpers/write_to_file.dart';
import 'package:sport_log/models/cardio/position.dart';

Result<List<Position>, String> gpxToTrack(String gpxString) {
  final Gpx gpx;
  try {
    gpx = GpxReader().fromString(gpxString);
  } on StateError {
    return Err("Parsing file failed. This file is not valid GPX.");
  }
  final points =
      gpx.trks.map((t) => t.trksegs).flattened.map((t) => t.trkpts).flattened;
  final startTime = points
      .map((p) => p.time)
      .firstWhere((element) => element != null, orElse: () => null);
  final track = <Position>[];
  for (final point in points) {
    final lat = point.lat;
    final lng = point.lon;
    if (lat == null || lng == null) {
      continue;
    }
    track.add(
      Position(
        longitude: lng,
        latitude: lat,
        elevation: point.ele ?? 0.0,
        distance:
            track.isEmpty
                ? 0
                : track.last.distance +
                    track.last.latLng.distanceTo(LatLng(lat: lat, lng: lng)),
        time:
            startTime == null || point.time == null
                ? Duration.zero
                : point.time!.difference(startTime),
      ),
    );
  }
  return Ok(track);
}

String trackToGpx(List<Position> track, {DateTime? startTime}) {
  final points =
      track
          .map(
            (p) => Wpt(
              lon: p.longitude,
              lat: p.latitude,
              ele: p.elevation,
              time: startTime?.add(p.time),
            ),
          )
          .toList();
  final gpx =
      Gpx()
        ..creator = "Sport Log"
        ..trks.add(Trk(trksegs: [Trkseg(trkpts: points)]));
  return GpxWriter().asString(gpx);
}

Future<Result<String, void>> saveTrackAsGpx(
  List<Position> track, {
  DateTime? startTime,
}) async {
  final file = await writeToFile(
    content: trackToGpx(track, startTime: startTime),
    filename: "track",
    fileExtension: "gpx",
  );
  if (file.isOk) {
    await NotificationController.showFileNotification(
      'Track Exported',
      file.ok,
    );
  }
  return file;
}

Future<Result<List<Position>, String>?> loadTrackFromGpxFile() async {
  await FilePicker.platform.clearTemporaryFiles();
  final result = await FilePicker.platform.pickFiles();
  if (result == null) {
    return null;
  }
  final file = File(result.files.single.path!);
  final String gpxString;
  try {
    gpxString = await file.readAsString();
  } catch (e) {
    return Err(e.toString());
  }
  return gpxToTrack(gpxString);
}
