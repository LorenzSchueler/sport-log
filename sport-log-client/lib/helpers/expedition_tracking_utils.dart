import 'dart:async';

import 'package:collection/collection.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:sport_log/data_provider/data_providers/cardio_data_provider.dart';
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
    this.cardioSessionDescription,
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
    assert(!created);
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
  static ExpeditionTrackingUtils attach(
    CardioSessionDescription cardioSessionDescription,
  ) {
    assert(created);
    return ExpeditionTrackingUtils._(
      cardioSessionDescription,
      Settings.instance.expeditionData!,
      true,
    );
  }

  final _logger = Logger("ExpeditionTrackingUtils");
  final _dataProvider = CardioSessionDescriptionDataProvider();
  final _locationUtils = LocationUtils();
  final TrackingUiUtils _trackingUiUtils = TrackingUiUtils();

  final CardioSessionDescription cardioSessionDescription;
  final ExpeditionData _expeditionData;
  final bool _attached;

  Timer? _locationTimer;
  Timer? _locationTimeoutTimer;
  static const Duration _maxLocationTaskDuration = Duration(minutes: 5);

  static bool get created => Settings.instance.expeditionData != null;
  bool get running => _locationTimer != null;

  @override
  void dispose() {
    _locationTimer?.cancel();
    _locationTimeoutTimer?.cancel();
    _locationUtils.dispose();
    super.dispose();
  }

  Future<void> onMapCreated(MapController mapController) async {
    await _trackingUiUtils.onMapCreated(
      mapController,
      cardioSessionDescription.route,
    );
  }

  Future<void> start() async {
    assert(!created);
    assert(!running);

    cardioSessionDescription.cardioSession.datetime = DateTime.now();
    await _dataProvider.createSingle(cardioSessionDescription);
    await Settings.instance.setExpeditionData(_expeditionData);
    _locationTimer = Timer(
      Duration.zero,
      expeditionTrackingTask,
    );
    notifyListeners();
  }

  Future<void> resume() async {
    assert(created);
    assert(!running);

    _locationTimer = Timer(
      Duration.zero,
      expeditionTrackingTask,
    );
    notifyListeners();
  }

  Future<void> stop(BuildContext context) async {
    assert(created);
    assert(running);

    await Settings.instance.setExpeditionData(null);
    _locationTimer?.cancel();
    _locationTimer = null;
    _locationTimeoutTimer?.cancel();
    _locationTimeoutTimer = null;
    if (context.mounted) {
      Navigator.pop(context); // pop tracking page
      if (!_attached) {
        Navigator.pop(context); // pop tracking settings page
      }
    }
  }

  // ignore: long-method
  Future<void> expeditionTrackingTask() async {
    _logger.i("task started");

    final session = cardioSessionDescription.cardioSession;

    await _locationUtils.startLocationStream(
      onLocationUpdate: (location) async {
        if (location.isGps) {
          _logger.i("got location $location");
          await _locationUtils.stopLocationStream();
          _locationTimeoutTimer?.cancel();
          _locationTimeoutTimer = null;

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

          await _dataProvider.updateSingle(cardioSessionDescription);
          await _trackingUiUtils.updateTrack(session.track);
          notifyListeners();
          _logger.i("new location added");
          await scheduleNextLocation();
        } else {
          _logger.d("got inaccurate location $location");
        }
      },
      inBackground: true,
    );
    _logger.i("location stream started");
    _locationTimeoutTimer = Timer(_maxLocationTaskDuration, () async {
      _logger.i("location stream timed out");
      await _locationUtils.stopLocationStream();
      await scheduleNextLocation();
    });
  }

  Future<void> scheduleNextLocation() async {
    final nextLocation = nextLocationAt();
    _locationTimer =
        Timer(nextLocation.difference(DateTime.now()), expeditionTrackingTask);

    notifyListeners();
  }

  DateTime nextLocationAt() {
    final now = DateTime.now();
    final nowTime = TimeOfDay.fromDateTime(now);

    // if there is any later time schedule at this time on same day
    for (final trackingTime in _expeditionData.trackingTimes) {
      if (nowTime < trackingTime) {
        return now.copyWith(
          hour: trackingTime.hour,
          minute: trackingTime.minute,
          second: 0,
        );
      }
    }
    // otherwise schedule at earliest time on next day
    final first = _expeditionData.trackingTimes.first;
    return now
        .copyWith(
          hour: first.hour,
          minute: first.minute,
          second: 0,
        )
        .add(const Duration(days: 1));
  }
}
