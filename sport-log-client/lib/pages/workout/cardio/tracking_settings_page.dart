import 'package:flutter/material.dart' hide Route;
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/heart_rate_utils.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/pages/workout/cardio/audio_feedback_config.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/input_fields/double_input.dart';
import 'package:sport_log/widgets/input_fields/edit_tile.dart';
import 'package:sport_log/widgets/input_fields/int_input.dart';
import 'package:sport_log/widgets/picker/picker.dart';
import 'package:sport_log/widgets/provider_consumer.dart';
import 'package:sport_log/widgets/snackbar.dart';

class CardioTrackingSettingsPage extends StatefulWidget {
  const CardioTrackingSettingsPage({super.key});

  @override
  State<CardioTrackingSettingsPage> createState() =>
      CardioTrackingSettingsPageState();
}

class CardioTrackingSettingsPageState
    extends State<CardioTrackingSettingsPage> {
  Movement? _movement;
  CardioType _cardioType = CardioType.training;
  Route? _route;
  int? _routeAlarmDistance;
  AudioFeedbackConfig? _audioFeedback;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tracking Settings")),
      body: Container(
        padding: Defaults.edgeInsets.normal,
        child: ProviderConsumer<HeartRateUtils>(
          create: (_) => HeartRateUtils(),
          builder: (_, heartRateUtils, __) => ListView(
            children: [
              EditTile(
                leading: AppIcons.exercise,
                caption: "Movement",
                child: Text(_movement?.name ?? ""),
                onTap: () async {
                  final movement = await showMovementPicker(
                    selectedMovement: _movement,
                    cardioOnly: true,
                    distanceOnly: true,
                    context: context,
                  );
                  if (mounted && movement != null) {
                    setState(() => _movement = movement);
                  }
                },
              ),
              EditTile(
                leading: AppIcons.sports,
                caption: "Cardio Type",
                child: Text(_cardioType.name),
                onTap: () async {
                  final cardioType = await showCardioTypePicker(
                    selectedCardioType: _cardioType,
                    context: context,
                  );
                  if (mounted && cardioType != null) {
                    setState(() => _cardioType = cardioType);
                  }
                },
              ),
              EditTile(
                leading: AppIcons.map,
                caption: "Route to follow",
                child: Text(_route?.name ?? "No Route"),
                onTap: () async {
                  final route = await showRoutePicker(
                    selectedRoute: _route,
                    context: context,
                  );
                  if (mounted) {
                    setState(() {
                      if (route == null) {
                        return;
                      } else if (route.id == _route?.id) {
                        _route = null;
                      } else {
                        _route = route;
                      }
                    });
                  }
                },
              ),
              if (_route != null)
                Row(
                  children: [
                    EditTile(
                      leading: AppIcons.notification,
                      caption: "Alarm when off Route",
                      shrinkWidth: true,
                      child: SizedBox(
                        height: 29, // make it fit into EditTile
                        width: 34, // remove left padding
                        child: Switch(
                          value: _routeAlarmDistance != null,
                          onChanged: (alarm) => setState(() {
                            _routeAlarmDistance = alarm ? 50 : null;
                          }),
                        ),
                      ),
                    ),
                    Defaults.sizedBox.horizontal.big,
                    if (_routeAlarmDistance != null)
                      EditTile(
                        leading: null,
                        caption: "Maximal Distance (m)",
                        shrinkWidth: true,
                        child: IntInput(
                          onUpdate: (alarm) => setState(() {
                            _routeAlarmDistance = alarm;
                          }),
                          initialValue: 50,
                          minValue: 20,
                          maxValue: null,
                        ),
                      ),
                  ],
                ),
              EditTile.Switch(
                leading: Icons.record_voice_over_rounded,
                caption: "Audio Feedback",
                value: _audioFeedback != null,
                onChanged: (feedback) => setState(() {
                  _audioFeedback = feedback ? AudioFeedbackConfig() : null;
                }),
              ),
              if (_audioFeedback != null) ...[
                Padding(
                  // 24 icon + 15 padding
                  padding: const EdgeInsets.only(left: 24 + 15),
                  child: EditTile(
                    leading: null,
                    caption: "Feedback Interval (km)",
                    shrinkWidth: true,
                    child: DoubleInput(
                      onUpdate: (interval) => setState(() {
                        _audioFeedback!.interval = interval;
                      }),
                      initialValue: 1,
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
                      shrinkWrap: true,
                      itemCount: _audioFeedback!.metrics.length,
                      itemBuilder: (context, index) {
                        final metric = _audioFeedback!.metrics[index];
                        return Row(
                          children: [
                            SizedBox(
                              height: 32,
                              width: 34,
                              child: Switch(
                                value: metric.isEnabled,
                                onChanged: (enabled) => setState(() {
                                  metric.isEnabled = enabled;
                                }),
                              ),
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
              heartRateUtils.devices.isEmpty
                  ? EditTile(
                      leading: AppIcons.heartbeat,
                      caption: "Heart Rate Monitor",
                      child: Text(
                        heartRateUtils.isSearching
                            ? "Searching..."
                            : "No Device",
                      ),
                      onTap: () async {
                        await heartRateUtils.searchDevices();
                        if (mounted && heartRateUtils.devices.isEmpty) {
                          showSimpleToast(context, "No devices found.");
                        }
                      },
                    )
                  : EditTile(
                      leading: AppIcons.heartbeat,
                      caption: "Heart Rate Monitors",
                      onCancel: heartRateUtils.reset,
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton(
                          value: heartRateUtils.deviceId,
                          items: heartRateUtils.devices.entries
                              .map(
                                (d) => DropdownMenuItem(
                                  value: d.value,
                                  child: Text(d.key),
                                ),
                              )
                              .toList(),
                          onChanged: (deviceId) {
                            if (deviceId != null) {
                              heartRateUtils.deviceId = deviceId;
                            }
                          },
                          isDense: true,
                        ),
                      ),
                    ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _movement != null
                      ? () => Navigator.pushNamed(
                            context,
                            Routes.tracking,
                            arguments: [
                              _movement,
                              _cardioType,
                              _route,
                              _routeAlarmDistance,
                              heartRateUtils.deviceId != null
                                  ? heartRateUtils
                                  : null,
                            ],
                          )
                      : null,
                  child: const Text("OK"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
