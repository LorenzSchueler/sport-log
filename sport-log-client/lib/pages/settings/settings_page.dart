import 'dart:io';
import 'dart:math';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:sport_log/app.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/data_provider/sync.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/account.dart';
import 'package:sport_log/helpers/bool_toggle.dart';
import 'package:sport_log/helpers/extensions/navigator_extension.dart';
import 'package:sport_log/helpers/notification_controller.dart';
import 'package:sport_log/helpers/write_to_file.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/dialogs.dart';
import 'package:sport_log/widgets/input_fields/duration_input.dart';
import 'package:sport_log/widgets/input_fields/edit_tile.dart';
import 'package:sport_log/widgets/input_fields/int_input.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/pop_scopes.dart';
import 'package:sport_log/widgets/provider_consumer.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> checkSync(BuildContext context) async {
    await Sync.instance.sync(
      onNoInternet: () => showMessageDialog(
        context: context,
        title: "Server Unreachable",
        text:
            "The server could not be reached.\nPlease make sure you are connected to the internet and the server URL is right.",
      ),
    );
  }

  Future<void> _setSyncEnabled(BuildContext context, bool syncEnabled) async {
    await context.read<Settings>().setSyncEnabled(syncEnabled);
    if (context.mounted && syncEnabled) {
      await checkSync(context);
      await Sync.instance.startSync();
    } else {
      Sync.instance.stopSync();
    }
  }

  Future<void> _setServerUrl(BuildContext context, String serverUrl) async {
    final validated = Validator.validateUrl(serverUrl);
    if (validated == null) {
      await context.read<Settings>().setServerUrl(serverUrl);
      Sync.instance.stopSync();
      if (context.mounted) {
        await checkSync(context);
      }
      await Sync.instance.startSync();
    } else {
      await showMessageDialog(
        context: context,
        title: "Invalid Server URL",
        text: validated,
      );
    }
  }

  Future<void> _setUsername(BuildContext context, String username) async {
    final validated = Validator.validateUsername(username);
    if (validated == null) {
      final result = await Account.editUser(username: username);
      if (context.mounted && result.isErr) {
        await showMessageDialog(
          context: context,
          title: "Changing Username Failed",
          text: result.err.toString(),
        );
      }
    } else {
      await showMessageDialog(
        context: context,
        title: "Invalid Username",
        text: validated,
      );
    }
  }

  Future<void> _setPassword(BuildContext context, String password) async {
    final validated = Validator.validatePassword(password);
    if (validated == null) {
      final result = await Account.editUser(password: password);
      if (context.mounted && result.isErr) {
        await showMessageDialog(
          context: context,
          title: "Changing Password Failed",
          text: result.err.toString(),
        );
      }
    } else {
      await showMessageDialog(
        context: context,
        title: "Invalid Password",
        text: validated,
      );
    }
  }

  Future<void> _setEmail(BuildContext context, String email) async {
    final validated = Validator.validateEmail(email);
    if (validated == null) {
      final result = await Account.editUser(email: email);
      if (context.mounted && result.isErr) {
        await showMessageDialog(
          context: context,
          title: "Changing Email Failed",
          text: result.err.toString(),
        );
      }
    } else {
      await showMessageDialog(
        context: context,
        title: "Invalid Email",
        text: validated,
      );
    }
  }

  Future<void> _initSync(BuildContext context) async {
    final approved = await showApproveDialog(
      context: context,
      title: "Warning",
      text: "Conflicting entries will get lost.",
    );
    if (approved) {
      final result = await Account.newInitSync();
      if (context.mounted && result.isErr) {
        await showMessageDialog(
          context: context,
          title: "An Error Occurred",
          text: result.err.toString(),
        );
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    final approved = await showApproveDialog(
      context: context,
      title: "Logout",
      text:
          "Make sure you know you credentials before logging out. Otherwise you will lose access to your account and all your data.",
    );
    if (approved) {
      await Account.logout();
      final context = App.globalContext; // other context is no longer mounted
      if (context.mounted) {
        await Navigator.of(App.globalContext).newBase(Routes.landing);
      }
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final approved = await showApproveDialog(
      context: context,
      title: "Delete Account",
      text: "If you delete your account all data will be permanently lost.",
    );
    if (approved) {
      final result = await Account.delete();
      final context = App.globalContext; // other context is no longer mounted
      if (context.mounted) {
        if (result.isErr) {
          await showMessageDialog(
            context: context,
            title: "An Error Occurred",
            text: result.err.toString(),
          );
        } else {
          await Navigator.of(context).newBase(Routes.landing);
        }
      }
    }
  }

  Future<void> _exportDb(BuildContext context) async {
    final dbPath = File(
      "${(await getApplicationDocumentsDirectory()).parent.path}/databases/${Config.databaseName}",
    );
    final data = await dbPath.readAsBytes();
    final file = await writeBytesToFileInDownloads(
      content: data,
      filename: "sport-log",
      fileExtension: "sqlite",
    );
    if (file.isOk) {
      if (!await AwesomeNotifications().isNotificationAllowed()) {
        await AwesomeNotifications().requestPermissionToSendNotifications();
      }
      if (await AwesomeNotifications().isNotificationAllowed()) {
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: Random.secure().nextInt(1 << 31),
            channelKey: NotificationController.fileChannel,
            title: "Database Exported",
            body: file.ok,
            payload: {"file": file.ok},
          ),
          actionButtons: [
            NotificationActionButton(
              key: NotificationController.openFileAction,
              label: "Open",
            ),
          ],
        );
      }
      if (context.mounted) {
        await showMessageDialog(
          context: context,
          title: "Database Exported",
          text: file.ok,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return NeverPop(
      child: Scaffold(
        appBar: AppBar(title: const Text("Settings")),
        body: Padding(
          padding: Defaults.edgeInsets.normal,
          child: Consumer<Settings>(
            builder: (context, settings, _) => ListView(
              children: [
                const CaptionTile(caption: "Server Settings"),
                Defaults.sizedBox.vertical.small,
                if (!settings.accountCreated)
                  EditTile(
                    leading: AppIcons.sync,
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: () =>
                                Navigator.of(context).pushNamed(Routes.login),
                            child: const Text('Login'),
                          ),
                        ),
                        Defaults.sizedBox.horizontal.normal,
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.of(context)
                                .pushNamed(Routes.registration),
                            child: const Text('Register'),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (settings.accountCreated) ...[
                  EditTile.Switch(
                    caption: "Server Synchronization",
                    leading: AppIcons.sync,
                    value: settings.syncEnabled,
                    onChanged: (enabled) => _setSyncEnabled(context, enabled),
                  ),
                  TextFormField(
                    // use new initialValue if url changed
                    key: ValueKey(settings.serverUrl),
                    decoration: InputDecoration(
                      icon: const Icon(AppIcons.cloudUpload),
                      labelText: "Server URL",
                      suffixIcon: IconButton(
                        onPressed: settings.setDefaultServerUrl,
                        icon: const Icon(AppIcons.restore),
                      ),
                    ),
                    initialValue: settings.serverUrl,
                    validator: Validator.validateUrl,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    onFieldSubmitted: (serverUrl) =>
                        _setServerUrl(context, serverUrl),
                  ),
                ],
                if (settings.syncEnabled) ...[
                  EditTile(
                    leading: AppIcons.timeInterval,
                    caption: "Synchronization Interval (min)",
                    child: IntInput(
                      initialValue: settings.syncInterval.inMinutes,
                      minValue: 1,
                      maxValue: null,
                      onUpdate: (syncInterval) async {
                        await settings
                            .setSyncInterval(Duration(minutes: syncInterval));
                        Sync.instance.stopSync();
                        await Sync.instance.startSync();
                      },
                    ),
                  ),
                  EditTile.Switch(
                    leading: AppIcons.systemUpdate,
                    caption: "Check for Updates",
                    value: settings.checkForUpdates,
                    onChanged: settings.setCheckForUpdates,
                  ),
                ],
                Defaults.sizedBox.vertical.small,
                const Divider(),
                if (settings.accountCreated) ...[
                  const CaptionTile(caption: "Account"),
                  TextFormField(
                    // use new initialValue if username changed
                    key: ValueKey(settings.username),
                    decoration: const InputDecoration(
                      icon: Icon(AppIcons.account),
                      labelText: "Username",
                    ),
                    initialValue: settings.username,
                    validator: Validator.validateUsername,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    onFieldSubmitted: (username) =>
                        _setUsername(context, username),
                  ),
                  ProviderConsumer(
                    create: (_) => BoolToggle.on(),
                    builder: (context, obscure, _) => TextFormField(
                      // use new initialValue if password changed
                      key: ValueKey(settings.password),
                      decoration: InputDecoration(
                        icon: const Icon(AppIcons.key),
                        labelText: "Password",
                        suffixIcon: IconButton(
                          icon: obscure.isOn
                              ? const Icon(AppIcons.visibility)
                              : const Icon(AppIcons.visibilityOff),
                          onPressed: obscure.toggle,
                        ),
                      ),
                      obscureText: obscure.isOn,
                      initialValue: settings.password,
                      validator: Validator.validatePassword,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      onFieldSubmitted: (password) =>
                          _setPassword(context, password),
                    ),
                  ),
                  TextFormField(
                    // use new initialValue if email changed
                    key: ValueKey(settings.email),
                    decoration: const InputDecoration(
                      icon: Icon(AppIcons.email),
                      labelText: "Email",
                    ),
                    initialValue: settings.email,
                    validator: Validator.validateEmail,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    keyboardType: TextInputType.emailAddress,
                    onFieldSubmitted: (email) => _setEmail(context, email),
                  ),
                  Consumer<Sync>(
                    builder: (context, sync, _) => EditTile(
                      leading: AppIcons.sync,
                      child: Container(
                        constraints:
                            const BoxConstraints(minWidth: double.infinity),
                        child: ElevatedButton(
                          style: ButtonStyle(
                            foregroundColor: WidgetStateProperty.all(
                              Theme.of(context).colorScheme.errorContainer,
                            ),
                          ),
                          onPressed:
                              sync.isSyncing ? null : () => _initSync(context),
                          child: const Text('Init Sync'),
                        ),
                      ),
                    ),
                  ),
                  Consumer<Sync>(
                    builder: (context, sync, _) => EditTile(
                      leading: AppIcons.logout,
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ButtonStyle(
                                foregroundColor: WidgetStateProperty.all(
                                  Theme.of(context).colorScheme.error,
                                ),
                              ),
                              onPressed: sync.isSyncing
                                  ? null
                                  : () => _logout(context),
                              child: const Text('Logout'),
                            ),
                          ),
                          Defaults.sizedBox.horizontal.normal,
                          Expanded(
                            child: ElevatedButton(
                              style: ButtonStyle(
                                foregroundColor: WidgetStateProperty.all(
                                  Theme.of(context).colorScheme.error,
                                ),
                              ),
                              onPressed: sync.isSyncing
                                  ? null
                                  : () => _deleteAccount(context),
                              child: const Text('Delete Account'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Defaults.sizedBox.vertical.small,
                  const Divider(),
                ],
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
                  decoration: const InputDecoration(
                    icon: Icon(AppIcons.dumbbell),
                    labelText: "Weight Increment",
                  ),
                  keyboardType: TextInputType.number,
                  initialValue: settings.weightIncrement.toString(),
                  validator: Validator.validateDoubleGtZero,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  onFieldSubmitted: (increment) async {
                    if (Validator.validateDoubleGtZero(increment) == null) {
                      await settings
                          .setWeightIncrement(double.parse(increment));
                    }
                  },
                ),
                Defaults.sizedBox.vertical.small,
                EditTile(
                  leading: AppIcons.timeInterval,
                  caption: "Duration Increment",
                  child: DurationInput(
                    initialDuration: settings.durationIncrement,
                    onUpdate: settings.setDurationIncrement,
                    durationIncrement: const Duration(minutes: 1),
                    minDuration: const Duration(seconds: 1),
                  ),
                ),
                Defaults.sizedBox.vertical.small,
                const Divider(),
                const CaptionTile(caption: "Developer Mode"),
                EditTile.Switch(
                  caption: "Developer Mode",
                  leading: AppIcons.developerMode,
                  value: settings.developerMode,
                  onChanged: settings.setDeveloperMode,
                ),
                if (settings.developerMode)
                  EditTile(
                    leading: AppIcons.bulletedList,
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(minWidth: double.infinity),
                      child: ElevatedButton(
                        child: const Text('Dev Status'),
                        onPressed: () =>
                            Navigator.pushNamed(context, Routes.devStatus),
                      ),
                    ),
                  ),
                const Divider(),
                const CaptionTile(caption: "Export"),
                EditTile(
                  leading: AppIcons.upload,
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(minWidth: double.infinity),
                    child: ElevatedButton(
                      child: const Text('Export'),
                      onPressed: () => _exportDb(context),
                    ),
                  ),
                ),
                const Divider(),
                const CaptionTile(caption: "About"),
                EditTile(
                  leading: AppIcons.questionMark,
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(minWidth: double.infinity),
                    child: ElevatedButton(
                      child: const Text('About'),
                      onPressed: () =>
                          Navigator.pushNamed(context, Routes.about),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        drawer: const MainDrawer(selectedRoute: Routes.settings),
      ),
    );
  }
}
