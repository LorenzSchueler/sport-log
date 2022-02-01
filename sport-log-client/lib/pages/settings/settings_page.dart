import 'package:flutter/material.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/custom_icons.dart';
import 'package:sport_log/widgets/form_widgets/edit_tile.dart';
import 'package:sport_log/widgets/main_drawer.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  final _logger = Logger('SettingsPage');

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: Container(
          padding: const EdgeInsets.all(10),
          child: ListView(
            children: [
              EditTile(
                  caption: "Server Synchonization",
                  child: SizedBox(
                      height: 20,
                      child: Switch(
                        value: Settings.instance.serverEnabled,
                        onChanged: (serverEnabled) {
                          setState(() {
                            Settings.instance.serverEnabled = serverEnabled;
                          });
                        },
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )),
                  leading: Icons.sync),
              if (Settings.instance.serverEnabled)
                TextFormField(
                  decoration: const InputDecoration(
                    icon: Icon(Icons.computer),
                    labelText: "Server",
                    contentPadding: EdgeInsets.symmetric(vertical: 5),
                  ),
                  initialValue: Settings.instance.serverUrl,
                  style: const TextStyle(height: 1),
                  onFieldSubmitted: (serverUrl) => setState(() {
                    Settings.instance.serverUrl = serverUrl;
                  }),
                ),
              if (Settings.instance.serverEnabled)
                TextFormField(
                  decoration: const InputDecoration(
                    icon: Icon(CustomIcons.timeInterval),
                    labelText: "Synchonization Interval (min)",
                    contentPadding: EdgeInsets.symmetric(vertical: 5),
                  ),
                  keyboardType: TextInputType.number,
                  initialValue:
                      Settings.instance.syncInterval.inMinutes.toString(),
                  style: const TextStyle(height: 1),
                  onFieldSubmitted: (syncInterval) => setState(() {
                    Settings.instance.syncInterval =
                        Duration(minutes: int.parse(syncInterval));
                  }),
                ),
              EditTile(
                  caption: "Units",
                  child: SizedBox(
                      height: 24,
                      child: DropdownButtonHideUnderline(
                          child: DropdownButton(
                        value: Settings.instance.units,
                        items: [
                          DropdownMenuItem(
                              value: Units.metric,
                              child: Text(Units.metric.name)),
                          DropdownMenuItem(
                              value: Units.imperial,
                              child: Text(Units.imperial.name))
                        ],
                        underline: null,
                        onChanged: (units) {
                          if (units != null && units is Units) {
                            setState(() {
                              Settings.instance.units =
                                  UnitsFromString.fromString(units.name);
                            });
                          }
                        },
                      ))),
                  leading: Icons.sync),
            ],
          )),
      drawer: const MainDrawer(selectedRoute: Routes.settings),
    );
  }
}
