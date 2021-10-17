import 'package:flutter/material.dart' hide Route;
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/cardio_type_picker.dart';
import 'package:sport_log/widgets/movement_picker.dart';

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
        body: Column(
          children: [
            ListTile(
                leading: const Icon(Icons.sports),
                title: Text(_movement?.name ?? ""),
                subtitle: const Text("movement"),
                trailing: const Icon(Icons.edit),
                onTap: () async {
                  Movement? movement = await showMovementPickerDialog(context,
                      dismissable: false, cardioOnly: true);
                  setState(() {
                    _movement = movement;
                  });
                  _logger.i(_movement?.name);
                }),
            const Divider(),
            ListTile(
                leading: const Icon(Icons.sports),
                title: Text(_cardioType?.name ?? ""),
                subtitle: const Text("cardio type"),
                trailing: const Icon(Icons.edit),
                onTap: () async {
                  CardioType? cardioType = await showCardioTypePickerDialog(
                    context,
                    dismissable: false,
                  );
                  setState(() {
                    _cardioType = cardioType;
                  });
                  _logger.i(_cardioType?.name);
                }),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.map),
              title: Text(_route?.name ?? ""),
              subtitle: const Text("route to follow"),
              trailing: const Icon(Icons.edit),
            ),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: _movement != null && _cardioType != null
                        ? () => Navigator.of(context).pushNamed(
                            Routes.cardio.tracking,
                            arguments: [_movement!, _cardioType!, _route])
                        : null,
                    child: const Text("OK"))),
          ],
        ));
  }
}
