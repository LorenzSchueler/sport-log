import 'package:flutter/material.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/account.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/custom_icons.dart';
import 'package:sport_log/widgets/form_widgets/edit_tile.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/message_dialog.dart';

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
              const CaptionTile(caption: "Server Settings"),
              Defaults.sizedBox.vertical.small,
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
                    labelText: "Server URL",
                    contentPadding: EdgeInsets.symmetric(vertical: 5),
                  ),
                  initialValue: Settings.instance.serverUrl,
                  validator: Validator.validateUrl,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
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
                    validator: (syncInterval) =>
                        syncInterval != null && int.parse(syncInterval) <= 0
                            ? "Interval must be greater than 0"
                            : null,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    style: const TextStyle(height: 1),
                    onFieldSubmitted: (syncInterval) async {
                      final min = int.parse(syncInterval);
                      if (min > 0) {
                        setState(() {
                          Settings.instance.syncInterval =
                              Duration(minutes: min);
                        });
                      } else {
                        await showMessageDialog(
                            context: context,
                            text: "Interval must be greater than 0");
                      }
                    }),
              Defaults.sizedBox.vertical.small,
              const Divider(),
              const CaptionTile(caption: "User Settings"),
              TextFormField(
                decoration: const InputDecoration(
                  icon: Icon(Icons.supervised_user_circle),
                  labelText: "Username",
                  contentPadding: EdgeInsets.symmetric(vertical: 5),
                ),
                initialValue: Settings.instance.username,
                validator: Validator.validateUsername,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                style: const TextStyle(height: 1),
                onFieldSubmitted: (username) async {
                  final validated = Validator.validateUsername(username);
                  if (validated == null) {
                    final result = await Account.editUser(username: username);
                    if (result.isFailure) {
                      await showMessageDialog(
                          context: context,
                          title: "Changing Username Failed",
                          text: result.failure);
                    }
                  } else {
                    await showMessageDialog(
                        context: context,
                        title: "Changing Username Failed",
                        text: validated);
                  }
                  setState(() {});
                },
              ),
              TextFormField(
                decoration: const InputDecoration(
                  icon: Icon(Icons.key),
                  labelText: "Password",
                  contentPadding: EdgeInsets.symmetric(vertical: 5),
                ),
                initialValue: Settings.instance.password,
                validator: Validator.validatePassword,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                style: const TextStyle(height: 1),
                onFieldSubmitted: (password) async {
                  final validated = Validator.validatePassword(password);
                  if (validated == null) {
                    final result = await Account.editUser(password: password);
                    if (result.isFailure) {
                      await showMessageDialog(
                          context: context,
                          title: "Changing Password Failed",
                          text: result.failure);
                    }
                  } else {
                    await showMessageDialog(
                        context: context,
                        title: "Changing Password Failed",
                        text: validated);
                  }
                  setState(() {});
                },
              ),
              TextFormField(
                decoration: const InputDecoration(
                  icon: Icon(Icons.email),
                  labelText: "Email",
                  contentPadding: EdgeInsets.symmetric(vertical: 5),
                ),
                initialValue: Settings.instance.email,
                validator: Validator.validateEmail,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                style: const TextStyle(height: 1),
                onFieldSubmitted: (email) async {
                  final validated = Validator.validateEmail(email);
                  if (validated == null) {
                    final result = await Account.editUser(email: email);
                    if (result.isFailure) {
                      await showMessageDialog(
                          context: context,
                          title: "Changing Email Failed",
                          text: result.failure);
                    }
                  } else {
                    await showMessageDialog(
                        context: context,
                        title: "Changing Email Failed",
                        text: validated);
                  }
                  setState(() {});
                },
              ),
              Defaults.sizedBox.vertical.small,
              const Divider(),
              const CaptionTile(caption: "Other Settings"),
              Defaults.sizedBox.vertical.small,
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
