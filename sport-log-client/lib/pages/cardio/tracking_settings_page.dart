import 'package:flutter/material.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/routes.dart';
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

  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Tracking Settings"),
        ),
        body: Column(
          children: [
            ListTile(
              leading: Icon(Icons.sports),
              title: Text("???"),
              subtitle: Text("movement"),
              trailing: Icon(Icons.edit),
            ),
            ListTile(
              leading: Icon(Icons.sports),
              title: Text("???"),
              subtitle: Text("cardio type"),
              trailing: Icon(Icons.edit),
            ),
            ListTile(
              leading: Icon(Icons.map),
              title: Text("???"),
              subtitle: Text("follow route"),
              trailing: Icon(Icons.edit),
            ),
            Container(
                padding: EdgeInsets.symmetric(horizontal: 10),
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: () =>
                        Navigator.of(context).pushNamed(Routes.cardio.tracking),
                    child: const Text("OK"))),
          ],
        ));
  }
}
