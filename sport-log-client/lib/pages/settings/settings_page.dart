import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/routes.dart';
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

  SharedPreferences? _storage;

  @override
  void initState() {
    SharedPreferences.getInstance().then((storage) => setState(() {
          _storage = storage;
          _storage!.getBool("serverEnabled") ??
              _storage!.setBool("serverEnabled", true);
          _storage!.getString("serverUrl") ??
              _storage!.setString("serverUrl", "<default URL>"); // TODO
          _storage!.getInt("syncInterval") ??
              _storage!.setInt("syncInterval", 300);
          _storage!.getString("units") ??
              _storage!.setString("units", "metric");
        }));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: _storage == null
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
                            value: _storage!.getBool("serverEnabled")!,
                            onChanged: (serverEnabled) {
                              setState(() {
                                _storage!
                                    .setBool("serverEnabled", serverEnabled);
                              });
                            },
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          )),
                      leading: Icons.sync),
                  if (_storage!.getBool("serverEnabled")!)
                    TextFormField(
                      decoration: const InputDecoration(
                        icon: Icon(Icons.computer),
                        labelText: "Server",
                        contentPadding: EdgeInsets.symmetric(vertical: 5),
                      ),
                      initialValue: _storage!.getString("serverUrl"),
                      style: const TextStyle(height: 1),
                      onFieldSubmitted: (serverUrl) => setState(() {
                        _storage!.setString("serverUrl", serverUrl);
                      }),
                    ),
                  if (_storage!.getBool("serverEnabled")!)
                    TextFormField(
                      decoration: const InputDecoration(
                        icon: Icon(CustomIcons.timeInterval),
                        labelText: "Synchonization Interval (min)",
                        contentPadding: EdgeInsets.symmetric(vertical: 5),
                      ),
                      keyboardType: TextInputType.number,
                      initialValue:
                          (_storage!.getInt("syncInterval")! ~/ 60).toString(),
                      style: const TextStyle(height: 1),
                      onFieldSubmitted: (syncInterval) => setState(() {
                        _storage!.setInt(
                            "syncInterval", int.parse(syncInterval) * 60);
                      }),
                    ),
                  EditTile(
                      caption: "Units",
                      child: SizedBox(
                          height: 24,
                          child: DropdownButtonHideUnderline(
                              child: DropdownButton(
                            value: _storage!.getString("units"),
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
                                  _storage!.setString("units", units as String);
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
