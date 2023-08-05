import 'dart:io';
import 'dart:math';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:gpx/gpx.dart';
import 'package:result_type/result_type.dart';
import 'package:sport_log/helpers/lat_lng.dart';
import 'package:sport_log/helpers/notification_controller.dart';
import 'package:sport_log/helpers/write_to_file.dart';
import 'package:sport_log/models/cardio/position.dart';

Result<List<Position>, String> gpxToTrack(String gpxString) {
  final Gpx gpx;
  try {
    gpx = GpxReader().fromString(gpxString);
  } on StateError {
    return Failure("Parsing file failed. This file is not valid GPX.");
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
        distance: track.isEmpty
            ? 0
            : track.last.distance +
                track.last.latLng.distanceTo(LatLng(lat: lat, lng: lng)),
        time: startTime == null || point.time == null
            ? Duration.zero
            : point.time!.difference(startTime),
      ),
    );
  }
  return Success(track);
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
  final file = await writeToFile(
    content: trackToGpx(track, startTime: startTime),
    filename: "track",
    fileExtension: "gpx",
  );
  if (file != null) {
    if (!await AwesomeNotifications().isNotificationAllowed()) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
    if (await AwesomeNotifications().isNotificationAllowed()) {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: Random.secure().nextInt(1 << 31),
          channelKey: NotificationController.fileChannel,
          title: "Route GPX export",
          body: file,
          payload: {"file": file},
        ),
        actionButtons: [
          NotificationActionButton(
            key: NotificationController.openFileAction,
            label: "Open",
          )
        ],
      );
    }
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
    return Failure(e.toString());
  }
  return gpxToTrack(gpxString);
}
