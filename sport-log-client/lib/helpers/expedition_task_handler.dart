import 'dart:async';
import 'dart:isolate';

import 'package:flutter/material.dart' hide Route;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/data_provider/data_providers/cardio_data_provider.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/global_error_handler.dart';
import 'package:sport_log/helpers/expedition_tracking_utils.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/location_utils.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/cardio/all.dart';
import 'package:sport_log/settings.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class ExpeditionTaskHandler extends TaskHandler {
  final _logger = InitLogger("ExpeditionTaskHandler");
  bool _initialized = false;
  late final ExpeditionData _expeditionData;
  DateTime? _lastTry;

  static const Duration _maxLocationTaskDuration = Duration(minutes: 5);

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    _logger.i("onStart");
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    GlobalErrorHandler.run(() async {
      _logger.i("on event");
      if (!_initialized) {
        // can not be done in onStart because onRepeatEvent called before onStart finishes
        await initialize();
      }

      await expeditionTrackingTask();
    });
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    _logger.i("onDestroy");
  }

  Future<void> initialize() async {
    await Config.init();
    await Hive.initFlutter();
    await Settings.instance.init();
    if (Config.isWindows || Config.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    await AppDatabase.init();
    _initialized = true;
    _expeditionData = Settings.instance.expeditionData!;
    _logger.i("initialization done");
  }

  // ignore: long-method
  Future<void> expeditionTrackingTask() async {
    _logger.i("task started");

    if (!nextLocationNeeded()) {
      _logger.i("next location not yet needed");
      return;
    }

    _logger.i("next location needed");

    final dataProvider = CardioSessionDescriptionDataProvider();
    final cardioSessionDescription =
        (await dataProvider.getById(_expeditionData.cardioId))!;
    final session = cardioSessionDescription.cardioSession;

    Timer? locationTimeoutTimer;
    final locationUtils = LocationUtils();
    await locationUtils.startLocationStream(
      onLocationUpdate: (location) async {
        if (location.isGps) {
          _logger.i("got location $location");
          await locationUtils.stopLocationStream();
          locationTimeoutTimer?.cancel();
          locationTimeoutTimer = null;

          session.track ??= [];
          final track = session.track!;

          final position = Position(
            latitude: location.latitude,
            longitude: location.longitude,
            elevation: location.elevation,
            distance: track.isEmpty
                ? 0
                : track.last.distance +
                    track.last.latLng.distanceTo(location.latLng),
            time: DateTime.now().difference(session.datetime),
          );

          session
            ..track!.add(position)
            ..time = position.time
            ..setAscentDescent()
            ..setDistance();

          await dataProvider.updateSingle(cardioSessionDescription);
          _lastTry = DateTime.now();
          _logger.i("new location added");
        } else {
          _logger.d("got inaccurate location $location");
        }
      },
      inBackground: true,
      ignorePermissions: true,
    );
    _logger.i("location stream started");
    locationTimeoutTimer = Timer(_maxLocationTaskDuration, () async {
      await locationUtils.stopLocationStream();
      _lastTry = DateTime.now();
      _logger.i("location stream timed out");
    });
  }

  bool nextLocationNeeded() {
    final lastTry = _lastTry;
    if (lastTry == null) {
      return true;
    }

    final lastTryDate = DateTime(lastTry.year, lastTry.month, lastTry.day);
    final lastTryTime = TimeOfDay.fromDateTime(lastTry);
    final nowDateTime = DateTime.now();
    final nowDate =
        DateTime(nowDateTime.year, nowDateTime.month, nowDateTime.day);
    final nowTime = TimeOfDay.fromDateTime(nowDateTime);

    final trackingTimes = _expeditionData.trackingTimes;
    if (trackingTimes.isEmpty) {
      return false;
    }
    if (lastTryDate == nowDate) {
      assert(lastTryTime < nowTime);
      // if lastTryTime before any trackingTime but nowTime after trackingTime we need next location
      return trackingTimes.any(
        (trackingTime) => lastTryTime < trackingTime && trackingTime < nowTime,
      );
    } else {
      // lastTryDate < nowDate
      return lastTryTime < nowTime
          ? true // more than one day ago
          // if any trackingTime after lastTryTime (yesterday) or before nowTime (today) we need next location
          : trackingTimes.any(
              (trackingTime) =>
                  lastTryTime < trackingTime || trackingTime < nowTime,
            );
    }
  }
}
