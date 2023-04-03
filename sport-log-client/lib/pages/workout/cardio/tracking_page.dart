import 'dart:async';

import 'package:flutter/material.dart' hide Route;
import 'package:provider/provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/bool_toggle.dart';
import 'package:sport_log/helpers/heart_rate_utils.dart';
import 'package:sport_log/helpers/lat_lng.dart';
import 'package:sport_log/helpers/tracking_utils.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/pages/workout/cardio/cardio_value_unit_description_table.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/theme.dart';
import 'package:sport_log/widgets/map_widgets/mapbox_map_wrapper.dart';
import 'package:sport_log/widgets/map_widgets/static_mapbox_map.dart';
import 'package:sport_log/widgets/pop_scopes.dart';
import 'package:sport_log/widgets/provider_consumer.dart';

class CardioTrackingPage extends StatelessWidget {
  const CardioTrackingPage({
    required this.movement,
    required this.cardioType,
    required this.route,
    required this.routeAlarmDistance,
    required this.heartRateUtils,
    super.key,
  });

  final Movement movement;
  final CardioType cardioType;
  final Route? route;
  final int? routeAlarmDistance;
  final HeartRateUtils? heartRateUtils;

  Future<void> _saveDialog(
    BuildContext context,
    TrackingUtils trackingUtils,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Save Recording"),
        content: TextFormField(
          initialValue:
              trackingUtils.cardioSessionDescription.cardioSession.comments,
          onChanged: (comments) => trackingUtils
              .cardioSessionDescription.cardioSession.comments = comments,
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
            onPressed:
                trackingUtils.cardioSessionDescription.isValidBeforeSanitation()
                    ? () => trackingUtils.saveCardioSession(context)
                    : null,
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProviderConsumer(
      create: (_) => TrackingUtils(
        movement: movement,
        cardioType: cardioType,
        route: route,
        routeAlarmDistance: routeAlarmDistance,
        heartRateUtils: heartRateUtils,
      ),
      builder: (context, trackingUtils, _) => DiscardWarningOnPop(
        onDiscard: () => trackingUtils.deleteIfSaved(context),
        child: SafeArea(
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            body: ProviderConsumer(
              create: (_) => BoolToggle.off(),
              builder: (context, fullscreen, _) => Column(
                children: [
                  if (context.read<Settings>().developerMode)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(trackingUtils.locationInfo),
                        Text(trackingUtils.stepInfo),
                        Text(trackingUtils.heartRateInfo),
                      ],
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
                      onFullscreenToggle: fullscreen.setState,
                      onCenterLocationToggle: trackingUtils.setCenterLocation,
                      initialCameraPosition: LatLngZoom(
                        latLng: context.read<Settings>().lastGpsLatLng,
                        zoom: 15,
                      ),
                      onMapCreated: trackingUtils.onMapCreated,
                    ),
                  ),
                  ElevationMap(
                    onMapCreated: trackingUtils.onElevationMapCreated,
                  ),
                  if (!fullscreen.isOn)
                    Container(
                      padding: Defaults.edgeInsets.normal,
                      child: Column(
                        children: [
                          CardioValueUnitDescriptionTable(
                            cardioSessionDescription:
                                trackingUtils.cardioSessionDescription,
                            currentDuration: trackingUtils.currentDuration,
                            showCurrentElevation: true,
                          ),
                          Defaults.sizedBox.vertical.normal,
                          _TrackingPageButtons(
                            trackingMode: trackingUtils.mode,
                            onStart: trackingUtils.start,
                            onPause: trackingUtils.pause,
                            onResume: trackingUtils.resume,
                            onSave: () => _saveDialog(context, trackingUtils),
                            hasGPS: trackingUtils.lastLatLng != null,
                            hasHR: heartRateUtils == null ||
                                heartRateUtils!.isActive,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrackingPageButtons extends StatelessWidget {
  const _TrackingPageButtons({
    required this.trackingMode,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onSave,
    required this.hasGPS,
    required this.hasHR,
  });

  final TrackingMode trackingMode;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onSave;
  final bool hasGPS;
  final bool hasHR;

  @override
  Widget build(BuildContext context) {
    switch (trackingMode) {
      case TrackingMode.tracking:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: onPause,
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
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: onResume,
                child: const Text("Resume"),
              ),
            ),
            Defaults.sizedBox.horizontal.normal,
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: onSave,
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
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: hasGPS && hasHR ? onStart : null,
                child: Text(
                  !hasGPS
                      ? "Waiting on GPS"
                      : !hasHR
                          ? "Waiting on HR Monitor"
                          : "Start",
                ),
              ),
            ),
            Defaults.sizedBox.horizontal.normal,
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
