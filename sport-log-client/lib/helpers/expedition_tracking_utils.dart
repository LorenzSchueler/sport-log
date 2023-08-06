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
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(ExpeditionTaskHandler());
}

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
