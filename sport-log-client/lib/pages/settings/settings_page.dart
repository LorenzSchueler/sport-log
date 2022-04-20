import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/sync.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/account.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/input_fields/edit_tile.dart';
import 'package:sport_log/widgets/input_fields/int_input.dart';
import 'package:sport_log/widgets/input_fields/text_tile.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/dialogs/message_dialog.dart';
import 'package:sport_log/widgets/never_pop.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  Future<void> checkSync() async {
    await Sync.instance.sync(
      onNoInternet: () => showMessageDialog(
        context: context,
        text:
            "The server could not be reached.\nPlease make sure you are connected to the internet and the server URL is right.",
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NeverPop(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Settings"),
        ),
        body: Container(
          padding: Defaults.edgeInsets.normal,
          child: ListView(
            children: [
              const CaptionTile(caption: "Server Settings"),
              Defaults.sizedBox.vertical.small,
              EditTile(
                caption: "Server Synchronization",
                child: SizedBox(
                  height: 20,
                  width: 34,
                  child: Switch(
                    value: Settings.syncEnabled,
                    onChanged: (syncEnabled) async {
                      setState(() => Settings.syncEnabled = syncEnabled);
                      if (syncEnabled) {
                        await checkSync();
                        await Sync.instance.startSync();
                      } else {
                        Sync.instance.stopSync();
                      }
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                leading: AppIcons.sync,
              ),
              if (Settings.syncEnabled)
                TextFormField(
                  decoration: const InputDecoration(
                    icon: Icon(AppIcons.cloudUpload),
                    labelText: "Server URL",
                    contentPadding: EdgeInsets.symmetric(vertical: 5),
                  ),
                  initialValue: Settings.serverUrl,
                  validator: Validator.validateUrl,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  onFieldSubmitted: (serverUrl) async {
                    final validated = Validator.validateUrl(serverUrl);
                    if (validated == null) {
                      setState(() => Settings.serverUrl = serverUrl);
                      Sync.instance.stopSync();
                      await checkSync();
                      await Sync.instance.startSync();
                    } else {
                      await showMessageDialog(
                        context: context,
                        text: validated,
                      );
                    }
                  },
                ),
              if (Settings.syncEnabled)
                EditTile(
                  leading: AppIcons.timeInterval,
                  caption: "Synchronization Interval (min)",
                  child: IntInput(
                    initialValue: Settings.syncInterval.inMinutes,
                    setValue: (syncInterval) async {
                      if (syncInterval > 0) {
                        setState(() {
                          Settings.syncInterval =
                              Duration(minutes: syncInterval);
                        });
                        Sync.instance.stopSync();
                        await Sync.instance.startSync();
                      } else {
                        await showMessageDialog(
                          context: context,
                          text: "Interval must be greater than 0.",
                        );
                      }
                    },
                  ),
                ),
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
                onFieldSubmitted: (username) async {
                  final validated = Validator.validateUsername(username);
                  if (validated == null) {
                    final result = await Account.editUser(username: username);
                    if (mounted && result.isFailure) {
                      await showMessageDialog(
                        context: context,
                        title: "Changing Username Failed",
                        text: result.failure.toString(),
                      );
                    }
                  } else {
                    await showMessageDialog(context: context, text: validated);
                  }
                  if (mounted) {
                    setState(() {});
                  }
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
                onFieldSubmitted: (password) async {
                  final validated = Validator.validatePassword(password);
                  if (validated == null) {
                    final result = await Account.editUser(password: password);
                    if (mounted && result.isFailure) {
                      await showMessageDialog(
                        context: context,
                        title: "Changing Password Failed",
                        text: result.failure.toString(),
                      );
                    }
                  } else {
                    await showMessageDialog(context: context, text: validated);
                  }
                  if (mounted) {
                    setState(() {});
                  }
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
                keyboardType: TextInputType.emailAddress,
                onFieldSubmitted: (email) async {
                  final validated = Validator.validateEmail(email);
                  if (validated == null) {
                    final result = await Account.editUser(email: email);
                    if (mounted && result.isFailure) {
                      await showMessageDialog(
                        context: context,
                        title: "Changing Email Failed",
                        text: result.failure.toString(),
                      );
                    }
                  } else {
                    await showMessageDialog(context: context, text: validated);
                  }
                  if (mounted) {
                    setState(() {});
                  }
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
                        for (final unit in Units.values)
                          DropdownMenuItem(
                            value: unit,
                            child: Text(unit.name),
                          ),
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
                    ),
                  ),
                ),
                leading: AppIcons.sync,
              ),
              TextFormField(
                decoration: const InputDecoration(
                  icon: Icon(AppIcons.timeInterval),
                  labelText: "Weight Increment",
                  contentPadding: EdgeInsets.symmetric(vertical: 5),
                ),
                keyboardType: TextInputType.number,
                initialValue: Settings.weightIncrement.toString(),
                validator: Validator.validateDoubleGtZero,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onFieldSubmitted: (increment) async {
                  final validated = Validator.validateDoubleGtZero(increment);
                  if (validated == null) {
                    final weightIncrement = double.parse(increment);
                    setState(() => Settings.weightIncrement = weightIncrement);
                  }
                },
              ),
              Defaults.sizedBox.vertical.small,
              const Divider(),
              const CaptionTile(caption: "About"),
              GestureDetector(
                child: const TextTile(
                  leading: AppIcons.questionmark,
                  child: Text('About'),
                ),
                onTap: () => Navigator.pushNamed(context, Routes.about),
              )
            ],
          ),
        ),
        drawer: const MainDrawer(selectedRoute: Routes.settings),
      ),
    );
  }
}
