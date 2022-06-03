import 'dart:io';

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:gpx/gpx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/cardio/position.dart';

final _logger = Logger("Gpx");

List<Position>? gpxToTrack(String gpxString) {
  final Gpx gpx;
  try {
    gpx = GpxReader().fromString(gpxString);
  } on StateError {
    _logger.i("parsing gpx failed");
    return null;
  }
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

Future<String?> saveTrackAsGpx(
  List<Position> track, {
  DateTime? startTime,
}) async {
  if (!(await Permission.storage.request()).isGranted ||
      !(await Permission.accessMediaLocation.request()).isGranted) {
    _logger.i("permission denied");
    return null;
  }
  final dir = Config.isAndroid
      ? '/storage/emulated/0/Download'
      : Config.isIOS
          ? await getApplicationDocumentsDirectory()
          : (await getDownloadsDirectory())!;
  var file = File("$dir/track.gpx");
  var index = 1;
  while (await file.exists()) {
    file = File("$dir/track$index.gpx");
    index++;
  }
  final gpxString = trackToGpx(track, startTime: startTime);
  try {
    await file.writeAsString(gpxString, flush: true);
  } on FileSystemException catch (e) {
    _logger.w(e.toString());
    return null;
  }
  _logger.i("track exported to ${file.path}");
  return file.path;
}

Future<List<Position>?> loadTrackFromGpxFile() async {
  await FilePicker.platform.clearTemporaryFiles();
  FilePickerResult? result = await FilePicker.platform.pickFiles();

  if (result == null) {
    return null;
  }
  File file = File(result.files.single.path!);
  final gpxString = await file.readAsString();
  return gpxToTrack(gpxString);
}
