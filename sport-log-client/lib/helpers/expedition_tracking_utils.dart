import 'dart:async';
import 'dart:isolate';

import 'package:collection/collection.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/data_provider/data_providers/cardio_data_provider.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/global_error_handler.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/location_utils.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/map_controller.dart';
import 'package:sport_log/helpers/tracking_ui_utils.dart';
import 'package:sport_log/models/cardio/all.dart';
import 'package:sport_log/pages/workout/cardio/tracking_settings.dart';
import 'package:sport_log/settings.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class ExpeditionData {
  ExpeditionData({
    required this.cardioId,
    required this.trackingTimes,
  });

  final Int64 cardioId;
  final List<TimeOfDay> trackingTimes;
}

class ExpeditionTrackingUtils extends ChangeNotifier {
  ExpeditionTrackingUtils._(
    this._cardioSessionDescription,
    this._expeditionData,
    this._attached,
  )   : assert(_expeditionData.trackingTimes.isNotEmpty),
        assert(
          _expeditionData.trackingTimes.isSorted((x, y) => x < y ? -1 : 1),
        );

  // ignore: prefer_constructors_over_static_methods, unreachable_from_main
  static ExpeditionTrackingUtils create({
    required TrackingSettings trackingSettings,
  }) {
    assert(!running);
    final cardioId = randomId();
    final cardioSessionDescription = CardioSessionDescription(
      cardioSession: CardioSession.defaultValue(
        trackingSettings.movement.id,
      )
        ..id = cardioId
        ..cardioType = trackingSettings.cardioType
        ..routeId = trackingSettings.route?.id,
      movement: trackingSettings.movement,
      route: trackingSettings.route,
    );
    final expeditionData = ExpeditionData(
      cardioId: cardioId,
      trackingTimes: trackingSettings.expeditionTrackingTimes!.toList(),
    );
    return ExpeditionTrackingUtils._(
      cardioSessionDescription,
      expeditionData,
      false,
    );
  }

  // ignore: prefer_constructors_over_static_methods, unreachable_from_main
  static ExpeditionTrackingUtils attach(
    CardioSessionDescription cardioSessionDescription,
  ) {
    assert(running);
    return ExpeditionTrackingUtils._(
      cardioSessionDescription,
      Settings.instance.expeditionData!,
      true,
    );
  }

  final _logger = Logger("ExpeditionTrackingUtils");
  final _dataProvider = CardioSessionDescriptionDataProvider();
  final TrackingUiUtils _trackingUiUtils = TrackingUiUtils();

  CardioSessionDescription _cardioSessionDescription;
  CardioSessionDescription get cardioSessionDescription =>
      _cardioSessionDescription;
  final ExpeditionData _expeditionData;
  final bool _attached;

  Timer? _refreshTimer;

  static const Duration _maxLocationTaskDuration = Duration(minutes: 5);

  static bool get running => Settings.instance.expeditionData != null;

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> onMapCreated(MapController mapController) async {
    await _trackingUiUtils.onMapCreated(
      mapController,
      cardioSessionDescription.route,
    );
    await _trackingUiUtils
        .updateTrack(cardioSessionDescription.cardioSession.track);
    _refreshTimer =
        Timer.periodic(const Duration(minutes: 1), (_) => _refresh());
  }

  Future<void> _refresh() async {
    // called every minute
    if (await FlutterForegroundTask.isRunningService) {
      _logger.d("refreshing expedition tracking page");
      _cardioSessionDescription = (await _dataProvider
          .getById(Settings.instance.expeditionData!.cardioId))!;
      await _trackingUiUtils
          .updateTrack(cardioSessionDescription.cardioSession.track);
      notifyListeners();
    }
  }

  Future<void> start() async {
    assert(!running);
    assert(!await FlutterForegroundTask.isRunningService);

    if (!await LocationUtils.requestPermissions()) {
      return;
    }

    cardioSessionDescription.cardioSession.datetime = DateTime.now();
    await _dataProvider.createSingle(cardioSessionDescription);
    await Settings.instance.setExpeditionData(_expeditionData);
    notifyListeners();

    _logger.i("starting foreground service");
    await FlutterForegroundTask.startService(
      notificationTitle: "Expedition Tracking",
      notificationText: "Expedition Tracking is active",
      callback: startCallback,
    );
  }

  Future<void> stop(BuildContext context) async {
    assert(running);
    assert(await FlutterForegroundTask.isRunningService);

    await FlutterForegroundTask.stopService();
    await Settings.instance.setExpeditionData(null);
    _refreshTimer?.cancel();
    _refreshTimer = null;
    if (context.mounted) {
      Navigator.pop(context); // pop tracking page
      if (!_attached) {
        Navigator.pop(context); // pop tracking settings page
      }
    }
  }

  // ignore: long-method
  static Future<void> expeditionTrackingTask() async {
    final logger = Logger("ExpeditionTask")..i("task started");

    final expeditionData = Settings.instance.expeditionData;
    assert(expeditionData != null);

    final dataProvider = CardioSessionDescriptionDataProvider();
    final cardioSessionDescription =
        (await dataProvider.getById(expeditionData!.cardioId))!;
    final session = cardioSessionDescription.cardioSession;

    if (session.track != null && session.track!.isNotEmpty) {
      final lastDateTime = session.datetime.add(
        session.track!.last.time,
      );
      if (!nextLocationNeeded(expeditionData.trackingTimes, lastDateTime)) {
        logger.i("next location not yet needed");
        return;
      }
    }
    logger.i("next location needed");

    Timer? locationTimeoutTimer;
    final locationUtils = LocationUtils();
    await locationUtils.startLocationStream(
      onLocationUpdate: (location) async {
        if (location.isGps) {
          logger.i("got location $location");
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
          logger.i("new location added");
        } else {
          logger.d("got inaccurate location $location");
        }
      },
      inBackground: true,
      ignorePermissions: true,
    );
    logger.i("location stream started");
    locationTimeoutTimer = Timer(_maxLocationTaskDuration, () async {
      logger.i("location stream timed out");
      await locationUtils.stopLocationStream();
    });
  }

  static bool nextLocationNeeded(
    List<TimeOfDay> trackingTimes,
    DateTime lastDateTime,
  ) {
    final lastDate =
        DateTime(lastDateTime.year, lastDateTime.month, lastDateTime.day);
    final lastTime = TimeOfDay.fromDateTime(lastDateTime);
    final nowDateTime = DateTime.now();
    final nowDate =
        DateTime(nowDateTime.year, nowDateTime.month, nowDateTime.day);
    final nowTime = TimeOfDay.fromDateTime(nowDateTime);

    if (trackingTimes.isEmpty) {
      return false;
    }
    if (lastDate == nowDate) {
      assert(lastTime < nowTime);
      // if lastTime before any trackingTime but nowTime after trackingTime we need next location
      return trackingTimes.any(
        (trackingTime) => lastTime < trackingTime && trackingTime < nowTime,
      );
    } else {
      // lastDate < nowDate
      return lastTime < nowTime
          ? true // more than one day ago
          // if any trackingTime after lastTime (yesterday) or before nowTime (today) we need next location
          : trackingTimes.any(
              (trackingTime) =>
                  lastTime < trackingTime || trackingTime < nowTime,
            );
    }
  }
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(ExpeditionTaskHandler());
}

class ExpeditionTaskHandler extends TaskHandler {
  final logger = InitLogger("ExpeditionTaskHandler");
  bool initialized = false;

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    logger.i("onStart");
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    GlobalErrorHandler.run(() async {
      logger.i("on event");
      if (!initialized) {
        // can not be done in onStart because onRepeatEvent called before onStart finishes
        await Config.init();
        await Hive.initFlutter();
        await Settings.instance.init();
        if (Config.isWindows || Config.isLinux) {
          sqfliteFfiInit();
          databaseFactory = databaseFactoryFfi;
        }
        await AppDatabase.init();
        logger.i("initialization done");
        initialized = true;
      }

      await ExpeditionTrackingUtils.expeditionTrackingTask();
    });
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    logger.i("onDestroy");
  }
}
