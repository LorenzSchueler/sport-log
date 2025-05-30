import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:sport_log/app.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/data_provider/data_providers/app_data_provider.dart';
import 'package:sport_log/data_provider/data_providers/metcon_data_provider.dart';
import 'package:sport_log/data_provider/data_providers/movement_data_provider.dart';
import 'package:sport_log/data_provider/data_providers/server_version_data_provider.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/server_version/server_version.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/dialogs/dialogs.dart';

class Sync extends ChangeNotifier {
  Sync._() : _isSyncing = false;

  static final Sync instance = Sync._();

  final _logger = Logger('Sync');

  Timer? _syncTimer;

  bool _isSyncing;
  bool get isSyncing => _isSyncing;

  ServerVersion? _serverVersion;

  bool _checkedUpdates = false;

  Future<void> init() async {
    if (Config.instance.deleteDatabase) {
      _logger.i("removing last sync");
      await Settings.instance.setEpochMap(null);
    }
    await startSync();
  }

  // ignore: long-method
  Future<bool> sync({VoidCallback? onNoInternet}) async {
    if (!Settings.instance.userExists()) {
      _logger.d('sync cannot run: no user');
      return false;
    }
    if (!Settings.instance.syncEnabled) {
      _logger.d("sync cannot run: sync disabled");
      return false;
    }
    if (_isSyncing) {
      _logger.d("sync job already running");
      return false;
    }

    _logger.i("running synchronization");
    _isSyncing = true;
    notifyListeners();

    if (_serverVersion == null) {
      final serverVersionResult = await ServerVersionDataProvider()
          .getServerVersion(onNoInternet: onNoInternet);
      if (serverVersionResult.isOk) {
        _serverVersion = serverVersionResult.ok;
        if (!_serverVersion!.compatibleWithClientApiVersion()) {
          final context = App.globalContext;
          if (context.mounted) {
            // must be unawaited so that callback finished even if dialog context dropped
            unawaited(
              showMessageDialog(
                context: context,
                title: "Api Version Not Compatible",
                text:
                    "Client api version ${Config.apiVersion} is not compatible with server api versions: $_serverVersion\n"
                    "Server synchronization is no longer possible. Please update the app.",
              ),
            );
          }
          //stop sync completely
          stopSync();
          _isSyncing = false;
          notifyListeners();
          _logger.i("synchronization failed: incompatible api version");
          return false;
        }
      } else {
        // stop current sync but keep sync timer running
        _isSyncing = false;
        notifyListeners();
        _logger.i("synchronization failed: unable to retrieve api version");
        return false;
      }
    }

    if (Settings.instance.checkForUpdates && !_checkedUpdates) {
      await update(onNoInternet);
      _checkedUpdates = true;
    }

    var syncSuccessful = await EntityDataProvider.downSync(
      onNoInternet: onNoInternet,
    );
    if (syncSuccessful) {
      syncSuccessful = await EntityDataProvider.upSync(
        onNoInternet: onNoInternet,
      );
    }

    _isSyncing = false;
    notifyListeners();
    _logger.i("synchronization done");

    return syncSuccessful;
  }

  Future<void> update(VoidCallback? onNoInternet) async {
    final updateInfoResult = await AppDataProvider().getUpdateInfo(
      onNoInternet: onNoInternet,
    );
    // ignore err
    if (updateInfoResult.isErr) {
      return;
    }
    final updateInfo = updateInfoResult.ok;
    if (!updateInfo.newVersion) {
      return;
    }
    var context = App.globalContext;
    if (!context.mounted) {
      return;
    }
    final update = await showUpdateDialog(context);
    if (!update) {
      return;
    }
    context = App.globalContext;
    if (!context.mounted) {
      return;
    }
    await Navigator.of(context).pushNamed(Routes.update);
  }

  Future<void> startSync() async {
    if (!Settings.instance.userExists()) {
      _logger.d("sync cannot run: no user");
      return;
    }
    if (!Settings.instance.syncEnabled) {
      _logger.d("sync cannot run: sync disabled");
      return;
    }
    if (_syncTimer != null && _syncTimer!.isActive) {
      _logger.d("sync already enabled");
      return;
    }
    _logger.i("starting synchronization timer");
    _syncTimer = Timer.periodic(Settings.instance.syncInterval, (_) => sync());
    if (Settings.instance.epochMap == null) {
      await sync(); // wait to make sure movement 1 and metcon 1 exist
      await MovementDataProvider().setDefaultMovement();
      await MetconDescriptionDataProvider().setDefaultMetconDescription();
    } else {
      unawaited(sync()); // let sync finish later
    }
  }

  void stopSync() {
    _logger.d("stopping synchronization");
    _serverVersion = null;
    _syncTimer?.cancel();
    _syncTimer = null;
  }
}
