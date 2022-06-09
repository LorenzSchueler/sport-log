import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sport_log/data_provider/sync.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/account.dart';
import 'package:sport_log/helpers/extensions/navigator_extension.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/theme.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/approve_dialog.dart';
import 'package:sport_log/widgets/dialogs/message_dialog.dart';
import 'package:sport_log/widgets/input_fields/edit_tile.dart';
import 'package:sport_log/widgets/input_fields/int_input.dart';
import 'package:sport_log/widgets/input_fields/text_tile.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/pop_scopes.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  Future<void> checkSync(BuildContext context) async {
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
          child: Consumer<Settings>(
            builder: (context, settings, _) => ListView(
              children: [
                const CaptionTile(caption: "Server Settings"),
                Defaults.sizedBox.vertical.small,
                EditTile(
                  caption: "Server Synchronization",
                  leading: AppIcons.sync,
                  child: settings.accountCreated
                      ? SizedBox(
                          height: 20,
                          width: 34,
                          child: Switch(
                            value: settings.syncEnabled,
                            onChanged: (syncEnabled) async {
                              settings.syncEnabled = syncEnabled;
                              if (syncEnabled) {
                                await checkSync(context);
                                await Sync.instance.startSync();
                              } else {
                                Sync.instance.stopSync();
                              }
                            },
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                      : ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(
                              Theme.of(context).colorScheme.errorContainer,
                            ),
                          ),
                          onPressed: () async {
                            settings
                              ..accountCreated = true
                              ..syncEnabled = true;
                            final result = await Account.register(
                              settings.serverUrl,
                              settings.user!,
                            );
                            if (result.isFailure) {
                              await showMessageDialog(
                                context: context,
                                title: "An Error occured:",
                                text: result.failure.toString(),
                              );
                              settings
                                ..accountCreated = false
                                ..syncEnabled = false;
                            }
                          },
                          child: const Text('Create Account'),
                        ),
                ),
                TextFormField(
                  decoration:
                      Theme.of(context).textFormFieldDecoration.copyWith(
                            icon: const Icon(AppIcons.cloudUpload),
                            labelText: "Server URL",
                          ),
                  initialValue: settings.serverUrl,
                  validator: Validator.validateUrl,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  onFieldSubmitted: (serverUrl) async {
                    final validated = Validator.validateUrl(serverUrl);
                    if (validated == null) {
                      settings.serverUrl = serverUrl;
                      Sync.instance.stopSync();
                      await checkSync(context);
                      await Sync.instance.startSync();
                    } else {
                      await showMessageDialog(
                        context: context,
                        text: validated,
                      );
                    }
                  },
                ),
                if (settings.syncEnabled)
                  EditTile(
                    leading: AppIcons.timeInterval,
                    caption: "Synchronization Interval (min)",
                    child: IntInput(
                      initialValue: settings.syncInterval.inMinutes,
                      minValue: 1,
                      setValue: (syncInterval) {
                        settings.syncInterval = Duration(minutes: syncInterval);
                        Sync.instance.stopSync();
                        Sync.instance.startSync();
                      },
                    ),
                  ),
                Defaults.sizedBox.vertical.small,
                const Divider(),
                const CaptionTile(caption: "Account"),
                TextFormField(
                  key: UniqueKey(),
                  decoration:
                      Theme.of(context).textFormFieldDecoration.copyWith(
                            icon: const Icon(AppIcons.account),
                            labelText: "Username",
                          ),
                  initialValue: settings.username,
                  validator: Validator.validateUsername,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  onFieldSubmitted: (username) async {
                    final validated = Validator.validateUsername(username);
                    if (validated == null) {
                      final result = await Account.editUser(username: username);
                      if (result.isFailure) {
                        await showMessageDialog(
                          context: context,
                          title: "Changing Username Failed",
                          text: result.failure.toString(),
                        );
                      }
                    } else {
                      await showMessageDialog(
                        context: context,
                        text: validated,
                      );
                    }
                  },
                ),
                TextFormField(
                  key: UniqueKey(),
                  decoration:
                      Theme.of(context).textFormFieldDecoration.copyWith(
                            icon: const Icon(AppIcons.key),
                            labelText: "Password",
                          ),
                  initialValue: settings.password,
                  validator: Validator.validatePassword,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  onFieldSubmitted: (password) async {
                    final validated = Validator.validatePassword(password);
                    if (validated == null) {
                      final result = await Account.editUser(password: password);
                      if (result.isFailure) {
                        await showMessageDialog(
                          context: context,
                          title: "Changing Password Failed",
                          text: result.failure.toString(),
                        );
                      }
                    } else {
                      await showMessageDialog(
                        context: context,
                        text: validated,
                      );
                    }
                  },
                ),
                TextFormField(
                  key: UniqueKey(),
                  decoration:
                      Theme.of(context).textFormFieldDecoration.copyWith(
                            icon: const Icon(AppIcons.email),
                            labelText: "Email",
                          ),
                  initialValue: settings.email,
                  validator: Validator.validateEmail,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  keyboardType: TextInputType.emailAddress,
                  onFieldSubmitted: (email) async {
                    final validated = Validator.validateEmail(email);
                    if (validated == null) {
                      final result = await Account.editUser(email: email);
                      if (result.isFailure) {
                        await showMessageDialog(
                          context: context,
                          title: "Changing Email Failed",
                          text: result.failure.toString(),
                        );
                      }
                    } else {
                      await showMessageDialog(
                        context: context,
                        text: validated,
                      );
                    }
                  },
                ),
                Consumer<Sync>(
                  builder: (context, sync, _) => TextTile(
                    leading: AppIcons.logout,
                    child: Row(
                      children: [
                        if (settings.accountCreated) ...[
                          Expanded(
                            child: ElevatedButton(
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all(
                                  Theme.of(context).colorScheme.errorContainer,
                                ),
                              ),
                              onPressed: sync.isSyncing
                                  ? null
                                  : () async {
                                      final approved = await showApproveDialog(
                                        context,
                                        "Warning",
                                        "Conflicting entries will get lost.",
                                      );
                                      if (approved) {
                                        final result =
                                            await Account.newInitSync();
                                        if (result.isFailure) {
                                          await showMessageDialog(
                                            context: context,
                                            text: result.failure.toString(),
                                          );
                                        }
                                      }
                                    },
                              child: const Text('Init Sync'),
                            ),
                          ),
                          Defaults.sizedBox.horizontal.normal,
                        ],
                        Expanded(
                          child: ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(
                                Theme.of(context).colorScheme.error,
                              ),
                            ),
                            onPressed: sync.isSyncing
                                ? null
                                : () async {
                                    final navigator = Navigator.of(context);
                                    final approved = await showApproveDialog(
                                      context,
                                      "Logout",
                                      "Make sure you know you credentials before logging out. Otherwise you will lose access to your account and all your data.",
                                    );
                                    if (approved) {
                                      await Account.logout();
                                      await navigator.newBase(Routes.landing);
                                    }
                                  },
                            child: const Text('Logout'),
                          ),
                        ),
                        if (settings.accountCreated) ...[
                          Defaults.sizedBox.horizontal.normal,
                          Expanded(
                            child: ElevatedButton(
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all(
                                  Theme.of(context).colorScheme.error,
                                ),
                              ),
                              onPressed: sync.isSyncing
                                  ? null
                                  : () async {
                                      final navigator = Navigator.of(context);
                                      final approved = await showApproveDialog(
                                        context,
                                        "Delete Account",
                                        "If you delete your account all data will be permanently lost.",
                                      );
                                      if (approved) {
                                        final result = await Account.delete();
                                        if (result.isFailure) {
                                          await showMessageDialog(
                                            context: context,
                                            text:
                                                "An error occured while deleting your account:\n${result.failure}",
                                          );
                                        } else {
                                          await navigator
                                              .newBase(Routes.landing);
                                        }
                                      }
                                    },
                              child: const Text('Delete Account'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Defaults.sizedBox.vertical.small,
                const Divider(),
                const CaptionTile(caption: "Other Settings"),
                Defaults.sizedBox.vertical.small,
                //EditTile(
                //caption: "Units",
                //child: SizedBox(
                //height: 24,
                //child: DropdownButtonHideUnderline(
                //child: DropdownButton(
                //value: settings.units,
                //items: [
                //for (final unit in Units.values)
                //DropdownMenuItem(
                //value: unit,
                //child: Text(unit.name),
                //),
                //],
                //onChanged: (units) {
                //if (units != null && units is Units) {
                //settings.units = units;
                //}
                //},
                //),
                //),
                //),
                //leading: AppIcons.sync,
                //),
                TextFormField(
                  decoration:
                      Theme.of(context).textFormFieldDecoration.copyWith(
                            icon: const Icon(AppIcons.timeInterval),
                            labelText: "Weight Increment",
                          ),
                  keyboardType: TextInputType.number,
                  initialValue: settings.weightIncrement.toString(),
                  validator: Validator.validateDoubleGtZero,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  onFieldSubmitted: (increment) async {
                    if (Validator.validateDoubleGtZero(increment) == null) {
                      settings.weightIncrement = double.parse(increment);
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
        ),
        drawer: const MainDrawer(selectedRoute: Routes.settings),
      ),
    );
  }
}
