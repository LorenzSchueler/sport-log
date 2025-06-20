import 'dart:async';

import 'package:flutter/material.dart' hide Route;
import 'package:provider/provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/bool_toggle.dart';
import 'package:sport_log/helpers/lat_lng.dart';
import 'package:sport_log/helpers/metronome_utils.dart';
import 'package:sport_log/helpers/tracking_utils.dart';
import 'package:sport_log/pages/workout/cardio/cardio_value_unit_description_table.dart';
import 'package:sport_log/pages/workout/cardio/tracking_settings.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/map_widgets/mapbox_map_wrapper.dart';
import 'package:sport_log/widgets/map_widgets/static_mapbox_map.dart';
import 'package:sport_log/widgets/pop_scopes.dart';
import 'package:sport_log/widgets/provider_consumer.dart';
import 'package:sport_log/widgets/swipe_button.dart';

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
          onChanged: (comments) =>
              trackingUtils.cardioSessionDescription.cardioSession.comments =
                  comments,
          decoration: const InputDecoration(labelText: "Comments"),
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
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NeverPop(
      child: SafeArea(
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: ProviderConsumer(
            create: (_) => TrackingUtils(trackingSettings: trackingSettings),
            builder: (context, trackingUtils, _) => ProviderConsumer(
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
                    child: Stack(
                      children: [
                        MapboxMapWrapper(
                          showFullscreenButton: true,
                          showMapStylesButton: true,
                          showSelectRouteButton: false,
                          showSetNorthButton: true,
                          showZoomButtons: true,
                          showCurrentLocationButton: false,
                          showCenterLocationButtonWhenEnabled: true,
                          showCenterLocationButtonAlways: true,
                          showAddLocationButton: false,
                          onFullscreenToggle: fullscreen.setState,
                          onCenterLocationToggle:
                              trackingUtils.setCenterLocation,
                          initialCameraPosition: LatLngZoom(
                            latLng: context.read<Settings>().lastGpsLatLng,
                            zoom: 15,
                          ),
                          onMapCreated: trackingUtils.onMapCreated,
                        ),
                        Positioned(top: 15, left: 15, child: _CadenceButton()),
                      ],
                    ),
                  ),
                  ElevationMap(
                    onMapCreated: trackingUtils.onElevationMapCreated,
                  ),
                  if (fullscreen.isOff)
                    Padding(
                      padding: Defaults.edgeInsets.normal,
                      child: Column(
                        children: [
                          CardioValueUnitDescriptionTable(
                            cardioSessionDescription:
                                trackingUtils.cardioSessionDescription,
                            currentDuration: trackingUtils.currentDuration,
                          ),
                          Defaults.sizedBox.vertical.small,
                          _TrackingPageButtons(
                            trackingMode: trackingUtils.mode,
                            onStart: trackingUtils.start,
                            onPause: trackingUtils.pause,
                            onResume: trackingUtils.resume,
                            onSave: () => _saveDialog(context, trackingUtils),
                            waitingOnLocation: !trackingUtils.hasLocation,
                            waitingOnAccurateLocation:
                                !trackingUtils.hasAccurateLocation,
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

class _CadenceButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ProviderConsumer(
      create: (_) => MetronomeUtils(),
      builder: (context, metronomeUtils, _) => metronomeUtils.isPlaying
          ? SegmentedButton<MetronomeAdjustment>(
              segments: [
                ButtonSegment(
                  value: MetronomeAdjustment.stop,
                  label: Text("${metronomeUtils.cadence} rpm"),
                  icon: const Icon(AppIcons.close),
                ),
                const ButtonSegment(
                  value: MetronomeAdjustment.increase,
                  icon: Icon(AppIcons.add),
                ),
                const ButtonSegment(
                  value: MetronomeAdjustment.decrease,
                  icon: Icon(AppIcons.remove),
                ),
              ],
              selected: const {},
              emptySelectionAllowed: true,
              onSelectionChanged: (selected) =>
                  metronomeUtils.adjustTimer(selected.first),
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(
                  Theme.of(context).colorScheme.primary,
                ),
                foregroundColor: const WidgetStatePropertyAll(Colors.black),
              ),
            )
          : IconButton.filled(
              onPressed: metronomeUtils.startTimer,
              icon: const Icon(AppIcons.gauge),
              color: Colors.black,
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
    required this.waitingOnLocation,
    required this.waitingOnAccurateLocation,
    required this.waitingOnHR,
  });

  final TrackingMode trackingMode;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onSave;
  final bool waitingOnLocation;
  final bool waitingOnAccurateLocation;
  final bool waitingOnHR;

  @override
  Widget build(BuildContext context) {
    return switch (trackingMode) {
      TrackingMode.tracking => ConstrainedBox(
        constraints: const BoxConstraints(minWidth: double.infinity),
        child: SwipeButton(
          onSwipe: onPause,
          thumbLabel: "Pause",
          color: Theme.of(context).colorScheme.error,
        ),
      ),
      TrackingMode.paused => Row(
        children: [
          Expanded(
            child: FilledButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
              ),
              onPressed: onResume,
              child: const Text("Resume"),
            ),
          ),
          Defaults.sizedBox.horizontal.normal,
          Expanded(
            child: FilledButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: onSave,
              child: const Text("Save"),
            ),
          ),
        ],
      ),
      TrackingMode.notStarted => Row(
        children: [
          Expanded(
            child: FilledButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
          ),
          Defaults.sizedBox.horizontal.normal,
          Expanded(
            child: FilledButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
              ),
              onPressed: waitingOnAccurateLocation || waitingOnHR
                  ? null
                  : onStart,
              child: Text(
                waitingOnLocation
                    ? "Waiting on Location"
                    : waitingOnAccurateLocation
                    ? "Waiting on Accurate Location"
                    : waitingOnHR
                    ? "Waiting on HR Monitor"
                    : "Start",
                style: waitingOnAccurateLocation || waitingOnHR
                    ? const TextStyle(fontSize: 14)
                    : null,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    };
  }
}
