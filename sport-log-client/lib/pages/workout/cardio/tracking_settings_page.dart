import 'package:flutter/material.dart' hide Route;
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/heart_rate_utils.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/input_fields/edit_tile.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tracking Settings"),
      ),
      body: Container(
        padding: Defaults.edgeInsets.normal,
        child: ProviderConsumer<HeartRateUtils>(
          create: (_) => HeartRateUtils.consumer(),
          builder: (_, heartRateUtils, __) => Column(
            children: [
              EditTile(
                leading: AppIcons.exercise,
                caption: "Movement",
                child: Text(_movement?.name ?? ""),
                onTap: () async {
                  Movement? movement = await showMovementPicker(
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
                child: Text("$_cardioType"),
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
                    setState(() => _route = route);
                  }
                },
              ),
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
                              _movement!,
                              _cardioType,
                              _route,
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
