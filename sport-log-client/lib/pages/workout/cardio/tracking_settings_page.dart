import 'package:flutter/material.dart' hide Route;
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/pages/workout/cardio/audio_feedback_config.dart';
import 'package:sport_log/pages/workout/cardio/tracking_settings.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/dialogs.dart';
import 'package:sport_log/widgets/input_fields/double_input.dart';
import 'package:sport_log/widgets/input_fields/edit_tile.dart';
import 'package:sport_log/widgets/input_fields/int_input.dart';
import 'package:sport_log/widgets/picker/datetime_picker.dart';
import 'package:sport_log/widgets/picker/picker.dart';
import 'package:sport_log/widgets/provider_consumer.dart';
import 'package:sport_log/widgets/snackbar.dart';

class CardioTrackingSettingsPage extends StatelessWidget {
  const CardioTrackingSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tracking Settings")),
      body: Padding(
        padding: Defaults.edgeInsets.normal,
        child: ProviderConsumer<TrackingSettings>(
          create: (_) => TrackingSettings(),
          builder: (_, trackingSettings, __) => ListView(
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
                leading: AppIcons.map,
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
                EditTile.Switch(
                  leading: AppIcons.notification,
                  caption: "Alarm when off Route",
                  shrinkWidth: true,
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
                      shrinkWidth: true,
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
              if (false)
                // ignore: dead_code
                EditTile.Switch(
                  leading: AppIcons.mountains,
                  trailing: AppIcons.info,
                  caption: "Expedition Mode",
                  value: trackingSettings.expeditionMode,
                  onChanged: (expeditionMode) =>
                      trackingSettings.expeditionMode = expeditionMode,
                  onTrailingTap: () => showMessageDialog(
                    context: context,
                    title: "Expedition Tracking",
                    text:
                        "Expedition tracking allows to track the location for a long time without draining the battery too much.\nThe location will be determined only at the defined tracking times. Once the location is found or if the location is not found within 5 minutes, tracking is suspended until the next tracking time.\nIf the app is killed, tracking will stop completely, however it can be manually resumed later.",
                  ),
                ),
              if (trackingSettings.expeditionMode)
                Padding(
                  // 24 icon + 15 padding
                  padding: const EdgeInsets.only(left: 24 + 15),
                  child: EditTile(
                    leading: null,
                    caption: "Tracking Times",
                    unboundedHeight: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount:
                              trackingSettings.expeditionTrackingTimes!.length,
                          itemBuilder: (context, index) => Row(
                            children: [
                              Text(
                                trackingSettings.expeditionTrackingTimes!
                                    .elementAt(index)
                                    .formatHm,
                              ),
                              Defaults.sizedBox.horizontal.normal,
                              IconButton(
                                onPressed: () =>
                                    trackingSettings.removeTrackingTime(index),
                                icon: const Icon(AppIcons.close),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                style: const ButtonStyle(
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                iconSize: 24,
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(AppIcons.add),
                          label: const Text("Tracking Time"),
                          // ignore: prefer-extracting-callbacks
                          onPressed: () async {
                            final time = await showScrollableTimePicker(
                              context: context,
                              initialTime: null,
                            );
                            if (time != null) {
                              trackingSettings.addTrackingTime(
                                TimeOfDay.fromDateTime(time),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              if (!trackingSettings.expeditionMode) ...[
                EditTile.Switch(
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
                      leading: null,
                      caption: "Feedback Interval (km)",
                      shrinkWidth: true,
                      child: DoubleInput(
                        // update if rounded to 100m
                        key: ValueKey(trackingSettings.audioFeedback!.interval),
                        onUpdate: (interval) => trackingSettings
                                .audioFeedback!.interval =
                            (interval * 10).round() * 100, // rounded to 100m
                        initialValue:
                            trackingSettings.audioFeedback!.interval / 1000.0,
                        minValue: 0.1,
                        maxValue: null,
                      ),
                    ),
                  ),
                  Padding(
                    // 24 icon + 15 padding
                    padding: const EdgeInsets.only(left: 24 + 15),
                    child: EditTile(
                      leading: null,
                      caption: "Feedback Metrics",
                      unboundedHeight: true,
                      child: ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount:
                            trackingSettings.audioFeedback!.metrics.length,
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
                            items:
                                trackingSettings.heartRateUtils.devices.entries
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
              ],
              FilledButton(
                onPressed:
                    trackingSettings.expeditionTrackingTimes?.isNotEmpty ?? true
                        ? () => Navigator.pushNamed(
                              context,
                              trackingSettings.expeditionMode
                                  ? Routes.expeditionTracking
                                  : Routes.tracking,
                              arguments: trackingSettings,
                            )
                        : null,
                child: Text(
                  trackingSettings.expeditionTrackingTimes?.isNotEmpty ?? true
                      ? "OK"
                      : "Tracking Times required",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
