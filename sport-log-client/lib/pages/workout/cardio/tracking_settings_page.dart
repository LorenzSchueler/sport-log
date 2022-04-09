import 'package:flutter/material.dart' hide Route;
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/heart_rate_utils.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/input_fields/edit_tile.dart';
import 'package:sport_log/widgets/picker/cardio_type_picker.dart';
import 'package:sport_log/widgets/picker/movement_picker.dart';
import 'package:sport_log/widgets/picker/route_picker.dart';

class CardioTrackingSettingsPage extends StatefulWidget {
  const CardioTrackingSettingsPage({Key? key}) : super(key: key);

  @override
  State<CardioTrackingSettingsPage> createState() =>
      CardioTrackingSettingsPageState();
}

class CardioTrackingSettingsPageState
    extends State<CardioTrackingSettingsPage> {
  Movement? _movement;
  CardioType? _cardioType;
  Route? _route;
  Map<String, String>? _devices;
  String? _heartRateMonitorId;
  bool _isSearchingHRMonitor = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tracking Settings"),
      ),
      body: Container(
        padding: Defaults.edgeInsets.normal,
        child: Column(
          children: [
            EditTile(
              leading: AppIcons.exercise,
              caption: "Movement",
              child: Text(_movement?.name ?? ""),
              onTap: () async {
                Movement? movement = await showMovementPicker(
                  context: context,
                  dismissable: false,
                  cardioOnly: true,
                  distanceOnly: true,
                );
                setState(() => _movement = movement);
              },
            ),
            EditTile(
              leading: AppIcons.sports,
              caption: "Cardio Type",
              child: Text(_cardioType?.displayName ?? ""),
              onTap: () async {
                CardioType? cardioType = await showCardioTypePicker(
                  context: context,
                  dismissable: false,
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
                  dismissable: false,
                );
                setState(() => _route = route);
              },
            ),
            _devices == null
                ? EditTile(
                    leading: AppIcons.heartbeat,
                    caption: "Heart Rate Monitor",
                    child: Text(_hrStatus),
                    onTap: () async {
                      setState(() => _isSearchingHRMonitor = true);
                      final devices = await HeartRateUtils.searchDevices();
                      setState(() {
                        _devices = devices;
                        _isSearchingHRMonitor = false;
                      });
                    },
                  )
                : EditTile(
                    leading: AppIcons.heartbeat,
                    caption: "Heart Rate Monitors",
                    child: SizedBox(
                      height: 24,
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton(
                          value: _heartRateMonitorId,
                          items: _devices!.entries
                              .map(
                                (d) => DropdownMenuItem(
                                  value: d.value,
                                  child: Text(d.key),
                                ),
                              )
                              .toList(),
                          underline: null,
                          onChanged: (deviceId) {
                            if (deviceId != null && deviceId is String) {
                              setState(() => _heartRateMonitorId = deviceId);
                            }
                          },
                        ),
                      ),
                    ),
                    onCancel: () => setState(() {
                      _devices = null;
                      _heartRateMonitorId = null;
                    }),
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
                            _heartRateMonitorId,
                          ],
                        )
                    : null,
                child: const Text("OK"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _hrStatus {
    if (_isSearchingHRMonitor) {
      return "searching...";
    } else if (_heartRateMonitorId == null) {
      return "no device";
    } else {
      return "device found";
    }
  }
}
