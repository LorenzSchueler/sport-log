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

  Settings? _settings;

  @override
  void initState() {
    Settings.get().then((settings) => setState(() {
          _settings = settings;
        }));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: _settings == null
          ? const Center(child: CircularProgressIndicator())
          : Container(
              padding: const EdgeInsets.all(10),
              child: ListView(
                children: [
                  EditTile(
                      caption: "Server Synchonization",
                      child: SizedBox(
                          height: 20,
                          child: Switch(
                            value: _settings!.serverEnabled,
                            onChanged: (serverEnabled) {
                              setState(() {
                                _settings!.serverEnabled = serverEnabled;
                              });
                            },
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          )),
                      leading: Icons.sync),
                  if (_settings!.serverEnabled)
                    TextFormField(
                      decoration: const InputDecoration(
                        icon: Icon(Icons.computer),
                        labelText: "Server",
                        contentPadding: EdgeInsets.symmetric(vertical: 5),
                      ),
                      initialValue: _settings!.serverUrl,
                      style: const TextStyle(height: 1),
                      onFieldSubmitted: (serverUrl) => setState(() {
                        _settings!.serverUrl = serverUrl;
                      }),
                    ),
                  if (_settings!.serverEnabled)
                    TextFormField(
                      decoration: const InputDecoration(
                        icon: Icon(CustomIcons.timeInterval),
                        labelText: "Synchonization Interval (min)",
                        contentPadding: EdgeInsets.symmetric(vertical: 5),
                      ),
                      keyboardType: TextInputType.number,
                      initialValue: (_settings!.syncInterval ~/ 60).toString(),
                      style: const TextStyle(height: 1),
                      onFieldSubmitted: (syncInterval) => setState(() {
                        _settings!.syncInterval = int.parse(syncInterval) * 60;
                      }),
                    ),
                  EditTile(
                      caption: "Units",
                      child: SizedBox(
                          height: 24,
                          child: DropdownButtonHideUnderline(
                              child: DropdownButton(
                            value: _settings!.units,
                            items: const [
                              DropdownMenuItem(
                                  value: "metric", child: Text("metric")),
                              DropdownMenuItem(
                                  value: "imperial", child: Text("imperial"))
                            ],
                            underline: null,
                            onChanged: (units) {
                              if (units != null) {
                                setState(() {
                                  _settings!.units = units as String;
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
