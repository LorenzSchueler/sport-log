import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier, VoidCallback;
import 'package:sport_log/api/api.dart';
import 'package:sport_log/app.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/data_provider/data_providers/metcon_data_provider.dart';
import 'package:sport_log/data_provider/data_providers/movement_data_provider.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/metcon/metcon_description.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/server_version/server_version.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/dialogs/dialogs.dart';

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
      await Settings.instance.setLastSync(null);
    }
    await startSync();
  }

  // ignore: long-method
  Future<bool> sync({VoidCallback? onNoInternet}) async {
    if (!Settings.instance.userExists()) {
      _logger.d('Sync cannot run: no user');
      return false;
    }
    if (!Settings.instance.syncEnabled) {
      _logger.i("Sync cannot run: sync disabled");
      return false;
    }
    if (_isSyncing) {
      _logger.d('Sync job already running');
      return false;
    }

    _isSyncing = true;
    notifyListeners();

    if (serverVersion == null) {
      final serverVersionResult = await Api.getServerVersion();
      if (serverVersionResult.isSuccess) {
        serverVersion = serverVersionResult.success;
        if (!serverVersion!.compatibleWithClientApiVersion()) {
          final context = App.globalContext;
          // must be unawaited so that callback finished even if dialog context dropped
          if (context.mounted) {
            unawaited(
              showMessageDialog(
                context: context,
                text:
                    "Client api version ${Config.apiVersion} is not compatible with server api versions: $serverVersion\n"
                    "Server synchronization is no longer possible. Please update the app.",
              ),
            );
          }
          //stop sync completely
          stopSync();
          _isSyncing = false;
          notifyListeners();
          return false;
        }
      } else {
        // stop current sync but keep sync timer running
        _isSyncing = false;
        notifyListeners();
        return false;
      }
    }

    var syncSuccessful =
        await EntityDataProvider.downSync(onNoInternet: onNoInternet);
    if (syncSuccessful) {
      syncSuccessful =
          await EntityDataProvider.upSync(onNoInternet: onNoInternet);
      // account for time difference
      final now = DateTime.now().add(const Duration(milliseconds: 100));
      _logger.i('Setting last sync to $now.');
      await Settings.instance.setLastSync(now);
    }

    _isSyncing = false;
    notifyListeners();

    return syncSuccessful;
  }

  Future<void> startSync() async {
    if (!Settings.instance.userExists()) {
      _logger.i('Sync cannot run: no user');
      return;
    }
    if (!Settings.instance.syncEnabled) {
      _logger.i("Sync cannot run: sync disabled");
      return;
    }
    if (_syncTimer != null && _syncTimer!.isActive) {
      _logger.d('Sync already enabled.');
      return;
    }
    _logger.d('Starting sync timer.');
    _syncTimer = Timer.periodic(Settings.instance.syncInterval, (_) => sync());
    if (Settings.instance.lastSync == null) {
      await sync(); // wait to make sure movement 1 and metcon 1 exist
    } else {
      unawaited(sync()); // let sync finish later
    }
    Movement.defaultMovement ??= await MovementDataProvider().getById(Int64(1));
    MetconDescription.defaultMetconDescription ??=
        await MetconDescriptionDataProvider().getById(Int64(1));
    return;
  }

  void stopSync() {
    _logger.d('Stopping synchronization.');
    serverVersion = null;
    _syncTimer?.cancel();
    _syncTimer = null;
  }
}
