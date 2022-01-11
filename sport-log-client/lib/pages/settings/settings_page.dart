import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/routes.dart';
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
          ? const CircularProgressIndicator()
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
                    )
                ],
              )),
      drawer: const MainDrawer(selectedRoute: Routes.settings),
    );
  }
}
