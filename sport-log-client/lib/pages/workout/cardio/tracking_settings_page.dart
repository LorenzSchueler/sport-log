import 'package:flutter/material.dart' hide Route;
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/pages/workout/cardio/audio_feedback_config.dart';
import 'package:sport_log/pages/workout/cardio/tracking_settings.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/input_fields/double_input.dart';
import 'package:sport_log/widgets/input_fields/duration_input.dart';
import 'package:sport_log/widgets/input_fields/edit_tile.dart';
import 'package:sport_log/widgets/input_fields/int_input.dart';
import 'package:sport_log/widgets/picker/picker.dart';
import 'package:sport_log/widgets/provider_consumer.dart';
import 'package:sport_log/widgets/snackbar.dart';

class CardioTrackingSettingsPage extends StatelessWidget {
  const CardioTrackingSettingsPage({required this.initMovement, super.key});

  final Movement initMovement;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tracking Settings")),
      body: Padding(
        padding: Defaults.edgeInsets.normal,
        child: ProviderConsumer<TrackingSettings>(
          create: (_) => TrackingSettings(initMovement),
          builder: (_, trackingSettings, _) => ListView(
            children: [
              EditTile(
                leading: AppIcons.movement,
                caption: "Movement",
                child: Text(trackingSettings.movement.name),
                onTap: () async {
                  final movement = await showMovementPicker(
                    selectedMovement: trackingSettings.movement,
                    cardioOnly: true,
                    distanceOnly: true,
                    context: context,
                  );
                  if (movement != null) {
                    trackingSettings.movement = movement;
                  }
                },
              ),
              EditTile(
                leading: AppIcons.sports,
                caption: "Cardio Type",
                child: Text(trackingSettings.cardioType.name),
                onTap: () async {
                  final cardioType = await showCardioTypePicker(
                    selectedCardioType: trackingSettings.cardioType,
                    context: context,
                  );
                  if (cardioType != null) {
                    trackingSettings.cardioType = cardioType;
                  }
                },
              ),
              EditTile(
                leading: AppIcons.stopwatch,
                caption: "Session to follow",
                child: Text(
                  trackingSettings.cardioSession?.datetime.humanDate ??
                      "No Session",
                ),
                onTap: () async {
                  final session = await showCardioSessionPicker(
                    selected: trackingSettings.cardioSession,
                    movement: trackingSettings.movement,
                    hasTrack: true,
                    context: context,
                  );
                  if (session == null) {
                    return;
                  } else if (session.id == trackingSettings.cardioSession?.id) {
                    trackingSettings.cardioSession = null;
                  } else {
                    trackingSettings.cardioSession = session;
                  }
                },
              ),
              EditTile(
                leading: AppIcons.route,
                caption: "Route to follow",
                child: Text(trackingSettings.route?.name ?? "No Route"),
                onTap: () async {
                  final route = await showRoutePicker(
                    selectedRoute: trackingSettings.route,
                    context: context,
                  );
                  if (route == null) {
                    return;
                  } else if (route.id == trackingSettings.route?.id) {
                    trackingSettings.route = null;
                  } else {
                    trackingSettings.route = route;
                  }
                },
              ),
              if (trackingSettings.route != null) ...[
                EditTile.switch_(
                  leading: AppIcons.notification,
                  caption: "Alarm when off Route",
                  value: trackingSettings.routeAlarmDistance != null,
                  onChanged: (alarm) =>
                      trackingSettings.routeAlarmDistance = alarm ? 50 : null,
                ),
                if (trackingSettings.routeAlarmDistance != null)
                  Padding(
                    // 24 icon + 15 padding
                    padding: const EdgeInsets.only(left: 24 + 15),
                    child: EditTile(
                      leading: null,
                      caption: "Maximal Distance (m)",
                      child: IntInput(
                        onUpdate: (alarm) =>
                            trackingSettings.routeAlarmDistance = alarm,
                        initialValue: 50,
                        minValue: 20,
                        maxValue: null,
                      ),
                    ),
                  ),
              ],
              EditTile.switch_(
                leading: Icons.record_voice_over_rounded,
                caption: "Audio Feedback",
                value: trackingSettings.audioFeedback != null,
                onChanged: (feedback) => trackingSettings.audioFeedback =
                    feedback ? AudioFeedbackConfig() : null,
              ),
              if (trackingSettings.audioFeedback != null) ...[
                Padding(
                  // 24 icon + 15 padding
                  padding: const EdgeInsets.only(left: 24 + 15),
                  child: EditTile(
                    unboundedHeight: true,
                    leading: null,
                    caption: "Interval Type",
                    child: SegmentedButton(
                      segments: const [
                        ButtonSegment(
                          value: IntervalType.distance,
                          label: Text("Distance"),
                        ),
                        ButtonSegment(
                          value: IntervalType.time,
                          label: Text("Time"),
                        ),
                      ],
                      selected: {trackingSettings.audioFeedback!.intervalType},
                      onSelectionChanged: (selected) =>
                          trackingSettings.audioFeedback!.intervalType =
                              selected.first,
                      showSelectedIcon: false,
                    ),
                  ),
                ),
                Padding(
                  // 24 icon + 15 padding
                  padding: const EdgeInsets.only(left: 24 + 15),
                  child: trackingSettings.audioFeedback!.intervalType.isDistance
                      ? EditTile(
                          leading: null,
                          caption: "Interval (km)",
                          child: DoubleInput(
                            // update if rounded to 100m
                            key: ValueKey(
                              trackingSettings.audioFeedback!.interval,
                            ),
                            onUpdate: (interval) =>
                                trackingSettings.audioFeedback!.interval =
                                    (interval * 10).round() *
                                    100, // rounded to 100m
                            initialValue:
                                trackingSettings.audioFeedback!.interval /
                                1000.0,
                            minValue: 0.1,
                            maxValue: null,
                          ),
                        )
                      : EditTile(
                          leading: null,
                          caption: "Interval",
                          child: DurationInput(
                            onUpdate: (interval) =>
                                trackingSettings.audioFeedback!.interval =
                                    interval.inSeconds,
                            initialDuration: Duration(
                              seconds: trackingSettings.audioFeedback!.interval,
                            ),
                            minDuration: const Duration(seconds: 10),
                          ),
                        ),
                ),
                Padding(
                  // 24 icon + 15 padding
                  padding: const EdgeInsets.only(left: 24 + 15),
                  child: EditTile(
                    leading: null,
                    caption: "Metrics",
                    unboundedHeight: true,
                    child: ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: trackingSettings.audioFeedback!.metrics.length,
                      itemBuilder: (context, index) {
                        final metric =
                            trackingSettings.audioFeedback!.metrics[index];
                        return Row(
                          children: [
                            DefaultSwitch(
                              value: metric.isEnabled,
                              onChanged: (enabled) =>
                                  metric.isEnabled = enabled,
                            ),
                            Defaults.sizedBox.horizontal.normal,
                            Text(metric.name),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
              trackingSettings.heartRateUtils.devices.isEmpty
                  ? EditTile(
                      leading: AppIcons.heartbeat,
                      caption: "Heart Rate Monitor",
                      child: Text(
                        trackingSettings.heartRateUtils.isSearching
                            ? "Searching..."
                            : "No Device",
                      ),
                      onTap: () async {
                        await trackingSettings.heartRateUtils.searchDevices();
                        if (context.mounted &&
                            trackingSettings.heartRateUtils.devices.isEmpty) {
                          showSimpleToast(context, "No devices found.");
                        }
                      },
                    )
                  : EditTile(
                      leading: AppIcons.heartbeat,
                      caption: "Heart Rate Monitors",
                      onTrailingTap: trackingSettings.heartRateUtils.reset,
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton(
                          value: trackingSettings.heartRateUtils.deviceId,
                          items: trackingSettings.heartRateUtils.devices.entries
                              .map(
                                (d) => DropdownMenuItem(
                                  value: d.value,
                                  child: Text(d.key),
                                ),
                              )
                              .toList(),
                          onChanged: (deviceId) {
                            if (deviceId != null) {
                              trackingSettings.heartRateUtils.deviceId =
                                  deviceId;
                            }
                          },
                          isDense: true,
                        ),
                      ),
                    ),
              FilledButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  Routes.tracking,
                  arguments: trackingSettings,
                ),
                child: const Text("OK"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
