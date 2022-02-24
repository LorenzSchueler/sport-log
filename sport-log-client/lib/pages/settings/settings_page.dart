import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/sync.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/account.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/form_widgets/edit_tile.dart';
import 'package:sport_log/widgets/form_widgets/text_tile.dart';
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
                        value: Settings.serverEnabled,
                        onChanged: (serverEnabled) {
                          setState(() {
                            Settings.serverEnabled = serverEnabled;
                          });
                        },
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )),
                  leading: AppIcons.sync),
              if (Settings.serverEnabled)
                TextFormField(
                  decoration: const InputDecoration(
                    icon: Icon(AppIcons.cloudUpload),
                    labelText: "Server URL",
                    contentPadding: EdgeInsets.symmetric(vertical: 5),
                  ),
                  initialValue: Settings.serverUrl,
                  validator: Validator.validateUrl,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  style: const TextStyle(height: 1),
                  onFieldSubmitted: (serverUrl) async {
                    final validated = Validator.validateUrl(serverUrl);
                    if (validated == null) {
                      setState(() => Settings.serverUrl = serverUrl);
                    } else {
                      await showMessageDialog(
                          context: context, text: validated);
                    }
                  },
                ),
              if (Settings.serverEnabled)
                TextFormField(
                    decoration: const InputDecoration(
                      icon: Icon(AppIcons.timeInterval),
                      labelText: "Synchonization Interval (min)",
                      contentPadding: EdgeInsets.symmetric(vertical: 5),
                    ),
                    keyboardType: TextInputType.number,
                    initialValue: Settings.syncInterval.inMinutes.toString(),
                    validator: Validator.validateIntGtZero,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    style: const TextStyle(height: 1),
                    onFieldSubmitted: (syncInterval) async {
                      final validated =
                          Validator.validateIntGtZero(syncInterval);
                      if (validated == null) {
                        final min = int.parse(syncInterval);
                        setState(() {
                          Settings.syncInterval = Duration(minutes: min);
                        });
                        Sync.instance.stopSync();
                        Sync.instance.startSync();
                      } else {
                        await showMessageDialog(
                            context: context, text: validated);
                      }
                    }),
              Defaults.sizedBox.vertical.small,
              const Divider(),
              const CaptionTile(caption: "User Settings"),
              TextFormField(
                decoration: const InputDecoration(
                  icon: Icon(AppIcons.account),
                  labelText: "Username",
                  contentPadding: EdgeInsets.symmetric(vertical: 5),
                ),
                initialValue: Settings.username,
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
                    await showMessageDialog(context: context, text: validated);
                  }
                  setState(() {});
                },
              ),
              TextFormField(
                decoration: const InputDecoration(
                  icon: Icon(AppIcons.key),
                  labelText: "Password",
                  contentPadding: EdgeInsets.symmetric(vertical: 5),
                ),
                initialValue: Settings.password,
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
                    await showMessageDialog(context: context, text: validated);
                  }
                  setState(() {});
                },
              ),
              TextFormField(
                decoration: const InputDecoration(
                  icon: Icon(AppIcons.email),
                  labelText: "Email",
                  contentPadding: EdgeInsets.symmetric(vertical: 5),
                ),
                initialValue: Settings.email,
                validator: Validator.validateEmail,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                style: const TextStyle(height: 1),
                keyboardType: TextInputType.emailAddress,
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
                    await showMessageDialog(context: context, text: validated);
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
                        value: Settings.units,
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
                              Settings.units =
                                  UnitsFromString.fromString(units.name);
                            });
                          }
                        },
                      ))),
                  leading: AppIcons.sync),
              Defaults.sizedBox.vertical.small,
              const Divider(),
              const CaptionTile(caption: "About"),
              GestureDetector(
                  child: const TextTile(
                    leading: AppIcons.questionmark,
                    child: Text('About'),
                  ),
                  onTap: () => Navigator.pushNamed(context, Routes.about))
            ],
          )),
      drawer: const MainDrawer(selectedRoute: Routes.settings),
    );
  }
}
