// ignore_for_file: unreachable_from_main

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:sport_log/data_provider/data_providers/cardio_data_provider.dart';
import 'package:sport_log/helpers/expedition_task_handler.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/location_utils.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/map_controller.dart';
import 'package:sport_log/helpers/tracking_ui_utils.dart';
import 'package:sport_log/models/cardio/all.dart';
import 'package:sport_log/pages/workout/cardio/tracking_settings.dart';
import 'package:sport_log/settings.dart';

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

  // ignore: prefer_constructors_over_static_methods
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

  // ignore: prefer_constructors_over_static_methods
  static ExpeditionTrackingUtils attach() {
    assert(running);
    return ExpeditionTrackingUtils._(
      null,
      Settings.instance.expeditionData!,
      true,
    );
  }

  final _logger = Logger("ExpeditionTrackingUtils");
  final _dataProvider = CardioSessionDescriptionDataProvider();
  final TrackingUiUtils _trackingUiUtils = TrackingUiUtils();

  // in create then already set; if attach then loaded in onMapCreated
  CardioSessionDescription? _cardioSessionDescription;
  CardioSessionDescription? get cardioSessionDescription =>
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
    _cardioSessionDescription ??= (await _dataProvider
        // ignore: unnecessary_null_checks
        .getById(Settings.instance.expeditionData!.cardioId))!;
    notifyListeners();
    await _trackingUiUtils.onMapCreated(
      mapController,
      cardioSessionDescription?.route,
    );
    await _trackingUiUtils
        .updateTrack(cardioSessionDescription?.cardioSession.track);
    _refreshTimer =
        Timer.periodic(const Duration(minutes: 1), (_) => _refresh());
  }

  Future<void> _refresh() async {
    // called every minute
    if (await FlutterForegroundTask.isRunningService) {
      _logger.d("refreshing expedition tracking page");
      _cardioSessionDescription = (await _dataProvider
          // ignore: unnecessary_null_checks
          .getById(Settings.instance.expeditionData!.cardioId))!;
      await _trackingUiUtils
          .updateTrack(cardioSessionDescription?.cardioSession.track);
      notifyListeners();
    }
  }

  Future<void> start() async {
    assert(!running);
    assert(!await FlutterForegroundTask.isRunningService);

    if (!await LocationUtils.requestPermissions()) {
      return;
    }
    await LocationUtils.enableGPS();

    assert(cardioSessionDescription != null);
    cardioSessionDescription!.cardioSession.datetime = DateTime.now();
    await _dataProvider.createSingle(cardioSessionDescription!);
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
