import 'package:flutter/material.dart' hide Route;
import 'package:sport_log/helpers/logger.dart';
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
  final _logger = Logger('CardioTrackingSettingsPage');

  Movement? _movement;
  CardioType? _cardioType;
  Route? _route;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tracking Settings"),
      ),
      body: Container(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            EditTile(
              leading: AppIcons.sports,
              caption: "Movement",
              child: Text(_movement?.name ?? ""),
              onTap: () async {
                Movement? movement = await showMovementPicker(
                  context,
                  dismissable: false,
                  cardioOnly: true,
                );
                setState(() {
                  _movement = movement;
                });
                _logger.i(_movement?.name);
              },
            ),
            EditTile(
              leading: AppIcons.sports,
              caption: "Cardio Type",
              child: Text(_cardioType?.name ?? ""),
              onTap: () async {
                CardioType? cardioType = await showCardioTypePicker(
                  context,
                  dismissable: false,
                );
                setState(() {
                  _cardioType = cardioType;
                });
                _logger.i(_cardioType?.name);
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
                setState(() {
                  _route = route;
                });
                _logger.i(_cardioType?.name);
              },
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _movement != null && _cardioType != null
                    ? () => Navigator.pushNamed(
                          context,
                          Routes.cardio.tracking,
                          arguments: [_movement!, _cardioType!, _route],
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
}
