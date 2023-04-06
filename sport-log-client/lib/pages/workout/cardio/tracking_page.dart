import 'dart:async';

import 'package:flutter/material.dart' hide Route;
import 'package:provider/provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/bool_toggle.dart';
import 'package:sport_log/helpers/lat_lng.dart';
import 'package:sport_log/helpers/tracking_utils.dart';
import 'package:sport_log/pages/workout/cardio/cardio_value_unit_description_table.dart';
import 'package:sport_log/pages/workout/cardio/tracking_settings.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/theme.dart';
import 'package:sport_log/widgets/map_widgets/mapbox_map_wrapper.dart';
import 'package:sport_log/widgets/map_widgets/static_mapbox_map.dart';
import 'package:sport_log/widgets/pop_scopes.dart';
import 'package:sport_log/widgets/provider_consumer.dart';

class CardioTrackingPage extends StatelessWidget {
  const CardioTrackingPage({required this.trackingSettings, super.key});

  final TrackingSettings trackingSettings;

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
      create: (_) => TrackingUtils(trackingSettings: trackingSettings),
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
                          ),
                          Defaults.sizedBox.vertical.normal,
                          _TrackingPageButtons(
                            trackingMode: trackingUtils.mode,
                            onStart: trackingUtils.start,
                            onPause: trackingUtils.pause,
                            onResume: trackingUtils.resume,
                            onSave: () => _saveDialog(context, trackingUtils),
                            waitingOnHPS: trackingUtils.lastLatLng == null,
                            waitingOnHR: trackingUtils.waitingOnHR,
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
    required this.waitingOnHPS,
    required this.waitingOnHR,
  });

  final TrackingMode trackingMode;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onSave;
  final bool waitingOnHPS;
  final bool waitingOnHR;

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
                onPressed: waitingOnHPS || waitingOnHR ? null : onStart,
                child: Text(
                  waitingOnHPS
                      ? "Waiting on GPS"
                      : waitingOnHR
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
