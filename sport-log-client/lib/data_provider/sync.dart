import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier, VoidCallback;
import 'package:sport_log/api/api.dart';
import 'package:sport_log/app.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/data_provider/data_providers/metcon_data_provider.dart';
import 'package:sport_log/data_provider/data_providers/movement_data_provider.dart';
import 'package:sport_log/helpers/account.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/metcon/metcon_description.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/server_version/server_version.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/dialogs/message_dialog.dart';

class Sync extends ChangeNotifier {
  Sync._() : _isSyncing = false;

  static final Sync instance = Sync._();

  final _logger = Logger('Sync');

  Timer? _syncTimer;

  bool _isSyncing;
  bool get isSyncing => _isSyncing;

  ServerVersion? serverVersion;

  Future<void> init() async {
    if (Config.instance.deleteDatabase) {
      _logger.i('Removing last sync...');
      Settings.lastSync = null;
    }
    if (Settings.userExists()) {
      await startSync();
    }
  }

  Future<bool> sync({VoidCallback? onNoInternet}) async {
    if (!Settings.syncEnabled) {
      _logger.i("sync disabled.");
      return false;
    }
    if (_isSyncing) {
      _logger.d('Sync job already running.');
      return false;
    }
    if (!Settings.userExists()) {
      _logger.d('Sync cannot be run: no user.');
      return false;
    }
    _isSyncing = true;
    notifyListeners();
    if (serverVersion == null) {
      final serverVersionResult = await Api.getServerVersion();
      if (serverVersionResult.isSuccess) {
        serverVersion = serverVersionResult.success;
        if (!serverVersion!.comatibleWithClientApiVersion()) {
          await showMessageDialog(
            context: App.globalContext,
            text:
                "Client api version ${Config.apiVersion} is not compatible with server versions: $serverVersion\n"
                "Server synchronization is no longer possible. Please update the app.",
          );
          stopSync();
          _isSyncing = false;
          notifyListeners();
          return false;
        }
      }
    }
    final syncStart = DateTime.now();
    final downSyncSuccessful = await _downSync(onNoInternet: onNoInternet);
    if (downSyncSuccessful) {
      await _upSync();
      _logger.i('Setting last sync to $syncStart.');
      // make sure sync intervals overlap slightly in case client and server clocks differ a little bit
      Settings.lastSync = syncStart.subtract(const Duration(seconds: 10));
    }
    _isSyncing = false;
    notifyListeners();
    return downSyncSuccessful;
  }

  Future<void> _upSync() async {
    await EntityDataProvider.pushAllToServer();
  }

  Future<bool> _downSync({VoidCallback? onNoInternet}) async {
    final accountDataResult = await Api.accountData.get(Settings.lastSync);
    if (accountDataResult.isFailure) {
      await DataProvider.handleApiError(
        accountDataResult.failure,
        onNoInternet: onNoInternet,
      );
      return false;
    } else {
      final accountData = accountDataResult.success;
      if (accountData.user != null) {
        Account.updateUserFromDownSync(accountData.user!);
      }
      await EntityDataProvider.upsertAccountData(
        accountData,
        synchronized: true,
      );
      return true;
    }
  }

  Future<void> startSync() async {
    assert(Settings.userExists());
    if (!Settings.syncEnabled) {
      _logger.i("sync disabled.");
      return;
    }
    if (_syncTimer != null && _syncTimer!.isActive) {
      _logger.d('Sync already enabled.');
      return;
    }
    _logger.d('Starting sync timer.');
    if (Settings.lastSync == null) {
      await sync(); // wait to make sure movement 1 and metcon 1 exist
    } else {
      unawaited(sync()); // let sync finish later
    }
    Movement.defaultMovement ??= await MovementDataProvider().getById(Int64(1));
    MetconDescription.defaultMetconDescription ??=
        await MetconDescriptionDataProvider().getById(Int64(1));
    _syncTimer = Timer.periodic(Settings.syncInterval, (_) => sync());
    return;
  }

  void stopSync() {
    serverVersion = null;
    if (_syncTimer != null) {
      _logger.d('Stopping sync timer...');
      _syncTimer?.cancel();
      _syncTimer = null;
    }
  }
}
