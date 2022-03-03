import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:sport_log/api/api.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/data_provider/data_providers/metcon_data_provider.dart';
import 'package:sport_log/data_provider/data_providers/movement_data_provider.dart';
import 'package:sport_log/helpers/account.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/typedefs.dart';
import 'package:sport_log/models/metcon/metcon_description.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/dialogs/new_credentials_dialog.dart';

class Sync extends ChangeNotifier {
  final _logger = Logger('Sync');

  Timer? _syncTimer;

  bool _isSyncing;
  bool get isSyncing => _isSyncing;

  static final Sync instance = Sync._();
  Sync._() : _isSyncing = false;

  Future<void> init() async {
    if (Config.deleteDatabase) {
      _logger.i('Removing last sync...');
      Settings.lastSync = null;
    }
    if (Settings.userExists()) {
      await startSync();
    }
  }

  Future<void> sync({VoidCallback? onNoInternet}) async {
    if (_isSyncing == true) {
      _logger.d('Sync job already running.');
      return;
    }
    if (!Settings.userExists()) {
      _logger.d('Sync cannot be run: no user.');
      return;
    }
    _isSyncing = true;
    notifyListeners();
    final syncStart = DateTime.now();
    if (await _downSync(onNoInternet: onNoInternet)) {
      await _upSync();
      _logger.i('Setting last sync to $syncStart.');
      // make sure sync intervals overlap slightly in case client and server clocks differ a little bit
      Settings.lastSync = syncStart.subtract(const Duration(seconds: 10));
    }
    _isSyncing = false;
    notifyListeners();
  }

  Future<void> _upSync() async {
    await EntityDataProvider.pushAllToServer();
  }

  Future<bool> _downSync({VoidCallback? onNoInternet}) async {
    final accountDataResult = await Api.accountData.get(Settings.lastSync);
    if (accountDataResult.isFailure) {
      switch (accountDataResult.failure) {
        case ApiError.noInternetConnection:
          _logger.d(
            'Tried sync but got no Internet connection.',
            accountDataResult.failure,
          );
          if (onNoInternet != null) {
            onNoInternet();
          }
          break;
        case ApiError.unauthorized:
          _logger.w(
            'Tried sync but access unauthorized.',
            accountDataResult.failure,
          );
          await showNewCredentialsDialog();
          break;
        default:
          _logger.e(
            'Tried down sync, but got error.',
            accountDataResult.failure,
          );
          break;
      }
      return false;
    } else {
      final accountData = accountDataResult.success;
      if (accountData.user != null) {
        Account.updateUserFromDownSync(accountData.user!);
      }
      EntityDataProvider.upsertAccountData(accountData, synchronized: true);
      return true;
    }
  }

  Future<void> startSync() async {
    assert(Settings.userExists());
    if (_syncTimer != null && _syncTimer!.isActive) {
      _logger.d('Sync already enabled.');
      return;
    }
    _logger.d('Starting sync timer.');
    await sync();
    Movement.defaultMovement =
        (await MovementDataProvider.instance.getById(Int64(1)))!; // FIXME
    MetconDescription.defaultMetconDescription =
        (await MetconDescriptionDataProvider.instance
            .getById(Int64(1)))!; // FIXME
    _syncTimer = Timer.periodic(Settings.syncInterval, (_) => sync());
  }

  void stopSync() {
    if (_syncTimer != null) {
      _logger.d('Stopping sync timer...');
      _syncTimer?.cancel();
      _syncTimer = null;
    }
  }
}
