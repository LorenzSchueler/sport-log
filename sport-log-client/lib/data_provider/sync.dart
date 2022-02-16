import 'dart:async';

import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:sport_log/api/api.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/typedefs.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/form_widgets/new_credentials_dialog.dart';

import 'data_providers/all.dart';

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
      startSync();
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
      Settings.lastSync = syncStart;
    }
    _isSyncing = false;
    notifyListeners();
  }

  Future<void> _upSync() async {
    for (final dp in allDataProviders) {
      // TODO: this can be sped up
      await dp.pushToServer();
    }
    // TODO: upsync routes, cardio sessions, metcon sessions, movement muscle, training plan, metcon item, strength blueprint, cardio blueprint
  }

  Future<bool> _downSync({VoidCallback? onNoInternet}) async {
    final accountDataResult = await Api.accountData.get(Settings.lastSync);
    if (accountDataResult.isFailure) {
      switch (accountDataResult.failure) {
        case ApiError.noInternetConnection:
          _logger.d('Tried sync but got no Internet connection.',
              accountDataResult.failure);
          if (onNoInternet != null) {
            onNoInternet();
          }
          break;
        case ApiError.unauthorized:
          _logger.w(
              'Tried sync but access unauthorized.', accountDataResult.failure);
          showNewCredentialsDialog();
          break;
        default:
          _logger.e(
              'Tried down sync, but got error.', accountDataResult.failure);
          break;
      }
      return false;
    } else {
      final accountData = accountDataResult.success;
      AppDatabase.instance!.upsertAccountData(accountData, synchronized: true);
      // TODO: deal with user updates
      return true;
    }
  }

  void startSync() {
    assert(Settings.userExists());
    if (_syncTimer != null && _syncTimer!.isActive) {
      _logger.d('Sync already enabled.');
      return;
    }
    _logger.d('Starting sync timer.');
    Future(() => sync());
    _syncTimer = Timer.periodic(Settings.syncInterval, (_) => sync());
  }

  void stopSync() {
    if (_syncTimer != null) {
      // TODO: what if sync is running and database will be deleted?
      _logger.d('Stopping sync timer...');
      _syncTimer?.cancel();
      _syncTimer = null;
    }
  }

  List<DataProvider> get allDataProviders => [
        MovementDataProvider.instance,
        StrengthDataProvider.instance,
        MetconDataProvider.instance,
        DiaryDataProvider.instance,
        WodDataProvider.instance,
        ActionEventDataProvider.instance,
        ActionRuleDataProvider.instance,
        PlatformCredentialDataProvider.instance,
      ];
}
