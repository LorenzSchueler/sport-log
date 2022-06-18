import 'package:flutter/material.dart' hide Route;
import 'package:provider/provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/heart_rate_utils.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/input_fields/edit_tile.dart';
import 'package:sport_log/widgets/picker/cardio_type_picker.dart';
import 'package:sport_log/widgets/picker/movement_picker.dart';
import 'package:sport_log/widgets/picker/route_picker.dart';
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
  CardioType? _cardioType;
  Route? _route;
  final HeartRateUtils _heartRateUtils = HeartRateUtils();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tracking Settings"),
      ),
      body: Container(
        padding: Defaults.edgeInsets.normal,
        child: ChangeNotifierProvider<HeartRateUtils>.value(
          value: _heartRateUtils,
          child: Consumer<HeartRateUtils>(
            builder: (_, heartRateUtils, __) => Column(
              children: [
                EditTile(
                  leading: AppIcons.exercise,
                  caption: "Movement",
                  child: Text(_movement?.name ?? ""),
                  onTap: () async {
                    Movement? movement = await showMovementPicker(
                      context: context,
                      cardioOnly: true,
                      distanceOnly: true,
                    );
                    setState(() => _movement = movement);
                  },
                ),
                EditTile(
                  leading: AppIcons.sports,
                  caption: "Cardio Type",
                  child: Text(_cardioType?.toString() ?? ""),
                  onTap: () async {
                    CardioType? cardioType = await showCardioTypePicker(
                      context: context,
                    );
                    setState(() => _cardioType = cardioType);
                  },
                ),
                EditTile(
                  leading: AppIcons.map,
                  caption: "Route to follow",
                  child: Text(_route?.name ?? ""),
                  onTap: () async {
                    Route? route = await showRoutePicker(
                      context: context,
                    );
                    setState(() => _route = route);
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
                              if (deviceId != null && deviceId is String) {
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
                    onPressed: _movement != null && _cardioType != null
                        ? () => Navigator.pushNamed(
                              context,
                              Routes.cardio.tracking,
                              arguments: [
                                _movement!,
                                _cardioType!,
                                _route,
                                _heartRateUtils.deviceId != null
                                    ? _heartRateUtils
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
      ),
    );
  }
}
