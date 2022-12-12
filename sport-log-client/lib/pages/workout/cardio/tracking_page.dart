import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:location/location.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:pedometer/pedometer.dart';
import 'package:polar/polar.dart';
import 'package:provider/provider.dart';
import 'package:sport_log/data_provider/data_providers/cardio_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/extensions/location_data_extension.dart';
import 'package:sport_log/helpers/extensions/map_controller_extension.dart';
import 'package:sport_log/helpers/heart_rate_utils.dart';
import 'package:sport_log/helpers/location_utils.dart';
import 'package:sport_log/helpers/step_count_utils.dart';
import 'package:sport_log/helpers/tracking_utils.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/models/cardio/cardio_session_description.dart';
import 'package:sport_log/pages/workout/cardio/cardio_value_unit_description_table.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/theme.dart';
import 'package:sport_log/widgets/dialogs/message_dialog.dart';
import 'package:sport_log/widgets/map_widgets/mapbox_map_wrapper.dart';
import 'package:sport_log/widgets/pop_scopes.dart';
import 'package:sport_log/widgets/provider_consumer.dart';

class CardioTrackingPage extends StatefulWidget {
  const CardioTrackingPage({
    required this.route,
    required this.movement,
    required this.cardioType,
    required this.heartRateUtils,
    super.key,
  });

  final Movement movement;
  final CardioType cardioType;
  final Route? route;
  final HeartRateUtils? heartRateUtils;

  @override
  State<CardioTrackingPage> createState() => _CardioTrackingPageState();
}

class _CardioTrackingPageState extends State<CardioTrackingPage> {
  final _dataProvider = CardioSessionDescriptionDataProvider();

  late final CardioSessionDescription _cardioSessionDescription =
      CardioSessionDescription(
    cardioSession: CardioSession.defaultValue(widget.movement.id)
      ..cardioType = widget.cardioType
      ..time = Duration.zero
      ..track = []
      ..cadence = []
      ..heartRate = widget.heartRateUtils != null ? [] : null
      ..routeId = widget.route?.id,
    movement: widget.movement,
    route: widget.route,
  );

  bool _fullscreen = false;
  bool _centerLocation = true;

  String _locationInfo = "no data";
  String _stepInfo = "no data";
  String _heartRateInfo = "no data";

  late final Timer _timer =
      Timer.periodic(const Duration(seconds: 1), (Timer t) => _refresh());
  final TrackingUtils _trackingUtils = TrackingUtils();
  late final LocationUtils _locationUtils = LocationUtils(_onLocationUpdate);
  late final StepCountUtils _stepUtils = StepCountUtils(_onStepCountUpdate);
  late final HeartRateUtils _heartRateUtils =
      HeartRateUtils(_onHeartRateUpdate);

  late final MapboxMapController _mapController;
  Line? _line;
  List<Circle>? _currentLocationMarker;

  static const maxSpeed = 250;

  @override
  void dispose() {
    _timer.cancel();
    _stepUtils.stopStepCountStream();
    _locationUtils.stopLocationStream();
    _heartRateUtils.stopHeartRateStream(dispose: true);
    if (_locationUtils.lastLatLng != null) {
      Settings.instance.lastGpsLatLng = _locationUtils.lastLatLng!;
    }
    super.dispose();
  }

  Future<void> _saveCardioSession() async {
    _cardioSessionDescription.cardioSession.time =
        _trackingUtils.currentDuration;
    _cardioSessionDescription.cardioSession.setEmptyListsToNull();
    _cardioSessionDescription.cardioSession.setAscentDescent();
    _cardioSessionDescription.cardioSession.setAvgCadence();
    _cardioSessionDescription.cardioSession.setAvgHeartRate();
    _cardioSessionDescription.cardioSession.setDistance();
    final result = await _dataProvider.createSingle(_cardioSessionDescription);
    if (result.isSuccess) {
      if (mounted) {
        Navigator.pop(context); // pop dialog
        Navigator.pop(context); // pop tracking page
        Navigator.pop(context); // pop tracking settings page
      }
    } else {
      await showMessageDialog(
        context: context,
        text: 'Creating Cardio Session failed:\n${result.failure}',
      );
    }
  }

  void _refresh() {
    // called every second
    setState(() {
      if (_trackingUtils.isTracking) {
        _cardioSessionDescription.cardioSession.time =
            _trackingUtils.currentDuration;
      }
      _cardioSessionDescription.cardioSession.setAscentDescent();
      _cardioSessionDescription.cardioSession.setAvgCadence();
      _cardioSessionDescription.cardioSession.setAvgHeartRate();
      _cardioSessionDescription.cardioSession.setDistance();
    });
  }

  Future<void> _startStreams() async {
    await _locationUtils.startLocationStream();
    await _stepUtils.startStepCountStream();
    await widget.heartRateUtils?.startHeartRateStream();
  }

  void _onHeartRateUpdate(PolarHeartRateEvent event) {
    if (_trackingUtils.isTracking) {
      if (_cardioSessionDescription.cardioSession.heartRate!.isEmpty &&
          event.data.rrsMs.isNotEmpty) {
        _cardioSessionDescription.cardioSession.heartRate!
            .add(_trackingUtils.currentDuration);
      } else {
        for (final rr in event.data.rrsMs) {
          _cardioSessionDescription.cardioSession.heartRate!.add(
            _trackingUtils.currentDuration +
                Duration(milliseconds: -event.data.rrsMs.sum + rr),
          );
        }
      }
    }
    _heartRateInfo = "rr: ${event.data.rrsMs} ms\nhr: ${event.data.hr} bpm";
  }

  void _onStepCountUpdate(StepCount stepCount) {
    if (_trackingUtils.isTracking) {
      if (_cardioSessionDescription.cardioSession.cadence!.isEmpty) {
        _cardioSessionDescription.cardioSession.cadence!
            .add(_trackingUtils.currentDuration);
      } else {
        /// interpolate steps since last stepCount update
        int newSteps = stepCount.steps - _stepUtils.lastStepCount.steps;
        int timeDiff = stepCount.timeStamp
            .difference(_stepUtils.lastStepCount.timeStamp)
            .inMilliseconds;
        int avgTimeDiff = (timeDiff / newSteps).floor();
        for (int ms = 0; ms < timeDiff; ms += avgTimeDiff) {
          _cardioSessionDescription.cardioSession.cadence!.add(
            _trackingUtils.currentDuration +
                Duration(milliseconds: -timeDiff + ms),
          );
        }
      }
    }
    _stepInfo =
        "step count: ${stepCount.steps}\ntime: ${stepCount.timeStamp.formatHms}";
  }

  Future<void> _onLocationUpdate(LocationData location) async {
    // filter GPS jumps in tracking mode
    if (_trackingUtils.isTracking &&
        _cardioSessionDescription.cardioSession.track!.isNotEmpty) {
      final lastPosition = _cardioSessionDescription.cardioSession.track!.last;
      final km =
          lastPosition.distanceTo(location.latitude!, location.longitude!) /
              1000;
      final hour =
          (_trackingUtils.currentDuration - lastPosition.time).inMilliseconds /
              (1000 * 60 * 60);
      final speed = km / hour;
      if (speed > maxSpeed) {
        return;
      }
    }

    _locationInfo = """
provider:   ${location.provider}
accuracy: ${location.accuracy?.toInt()} m
time: ${location.time! ~/ 1000} s
satellites: ${location.satelliteNumber}
points:      ${_cardioSessionDescription.cardioSession.track?.length}""";

    if (_centerLocation) {
      await _mapController.animateCenter(location.latLng);
    }

    _currentLocationMarker = await _mapController.updateCurrentLocationMarker(
      _currentLocationMarker,
      location.latLng,
    );

    if (_trackingUtils.isTracking) {
      _cardioSessionDescription.cardioSession.track!.add(
        Position(
          latitude: location.latitude!,
          longitude: location.longitude!,
          elevation: location.altitude!,
          distance: _cardioSessionDescription.cardioSession.track!.isEmpty
              ? 0
              : _cardioSessionDescription.cardioSession.track!.last
                  .addDistanceTo(location.latitude!, location.longitude!),
          time: _trackingUtils.currentDuration,
        ),
      );
      await _mapController.updateTrackLine(
        _line,
        _cardioSessionDescription.cardioSession.track,
      );
    }
  }

  Future<void> _saveDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Save Recording"),
        content: TextFormField(
          onChanged: (comments) => setState(
            () => _cardioSessionDescription.cardioSession.comments = comments,
          ),
          decoration: Theme.of(context).textFormFieldDecoration.copyWith(
                labelText: "Comments",
              ),
          keyboardType: TextInputType.multiline,
          minLines: 1,
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Back"),
          ),
          TextButton(
            onPressed: _cardioSessionDescription.isValidBeforeSanitation()
                ? _saveCardioSession
                : null,
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  Future<void> _setTrackAndStartStreams() async {
    if (_cardioSessionDescription.route?.track != null) {
      await _mapController.addRouteLine(
        _cardioSessionDescription.route!.track!,
      );
    }
    await _startStreams();
  }

  @override
  Widget build(BuildContext context) {
    return DiscardWarningOnPop(
      child: SafeArea(
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: Column(
            children: [
              if (context.read<Settings>().developerMode)
                Padding(
                  padding: const EdgeInsets.only(top: 25, bottom: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_locationInfo),
                      Text(_stepInfo),
                      Text(_heartRateInfo),
                    ],
                  ),
                ),
              Expanded(
                child: MapboxMapWrapper(
                  showScale: true,
                  showFullscreenButton: true,
                  showMapStylesButton: true,
                  showSelectRouteButton: false,
                  showSetNorthButton: true,
                  showCurrentLocationButton: false,
                  showCenterLocationButton: true,
                  onFullscreenToggle: (fullscreen) =>
                      setState(() => _fullscreen = fullscreen),
                  onCenterLocationToggle: (centerLocation) async {
                    _centerLocation = centerLocation;
                    final lastLatLng = _locationUtils.lastLatLng;
                    if (_centerLocation && lastLatLng != null) {
                      await _mapController.animateCenter(lastLatLng);
                    }
                  },
                  initialCameraPosition: CameraPosition(
                    zoom: 15.0,
                    target: context.read<Settings>().lastGpsLatLng,
                  ),
                  onMapCreated: (MapboxMapController controller) =>
                      _mapController = controller,
                  onStyleLoadedCallback: _setTrackAndStartStreams,
                ),
              ),
              if (!_fullscreen)
                Container(
                  padding: Defaults.edgeInsets.normal,
                  child: ProviderConsumer<TrackingUtils>.value(
                    value: _trackingUtils,
                    builder: (context, trackingUtils, _) => Column(
                      children: [
                        CardioValueUnitDescriptionTable(
                          cardioSessionDescription: _cardioSessionDescription,
                          currentDuration: trackingUtils.currentDuration,
                          showCurrentElevation: true,
                        ),
                        Defaults.sizedBox.vertical.normal,
                        _TrackingPageButtons(
                          trackingUtils: trackingUtils,
                          onStart: widget.heartRateUtils == null ||
                                  widget.heartRateUtils!.isActive
                              ? () {
                                  trackingUtils.start();
                                  _cardioSessionDescription
                                      .cardioSession.datetime = DateTime.now();
                                }
                              : null,
                          onStop: _saveDialog,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackingPageButtons extends StatelessWidget {
  const _TrackingPageButtons({
    required this.trackingUtils,
    required this.onStart,
    required this.onStop,
  });

  final TrackingUtils trackingUtils;
  final VoidCallback? onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    switch (trackingUtils.mode) {
      case TrackingMode.tracking:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: trackingUtils.pause,
                child: const Text("Pause"),
              ),
            ),
          ],
        );
      case TrackingMode.paused:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                ),
                onPressed: trackingUtils.resume,
                child: const Text("Resume"),
              ),
            ),
            Defaults.sizedBox.horizontal.normal,
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: onStop,
                child: const Text("Save"),
              ),
            ),
          ],
        );
      case TrackingMode.notStarted:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                ),
                onPressed: onStart,
                child:
                    Text(onStart != null ? "Start" : "Waiting on HR Monitor"),
              ),
            ),
            Defaults.sizedBox.horizontal.normal,
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
            ),
          ],
        );
    }
  }
}
