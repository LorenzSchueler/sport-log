import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/data_provider/user_state.dart';
import 'package:sport_log/database/keys.dart';
import 'package:sport_log/helpers/logger.dart';

import 'data_providers/all.dart';

class Sync extends ChangeNotifier {
  static final Sync instance = Sync._();

  Future<void> init() async {
    _box = await Hive.openBox<DateTime>(Keys.lastSync);
    if (Config.deleteDatabase) {
      _removeLastSync();
    }
    if (UserState.instance.currentUser != null) {
      Future(() => sync());
      login();
    }
  }

  Future<void> sync() async {
    if (_isSyncing == true) {
      _logger.d('Sync is alread running.');
      return;
    }
    if (UserState.instance.currentUser == null) {
      _logger.d('Sync cannot be run: no user.');
      return;
    }
    _logger.i('Starting sync...');
    _isSyncing = true;
    notifyListeners();
    final syncStart = DateTime.now();
    await _upSync();
    await _downSync();
    _setLastSync(syncStart);
    _isSyncing = false;
    notifyListeners();
  }

  void login() {
    assert(UserState.instance.currentUser != null);
    if (UserState.instance.currentUser == null) {
      _logger.e('Login, but no user found.');
      return;
    }
    if (_syncTrigger != null && _syncTrigger!.isActive) {
      _logger.d('Login, but timer is active.');
      return;
    }
    _logger.d('Starting sync timer...');
    _syncTrigger = Timer.periodic(Config.syncInterval, (_) => sync());
  }

  void logout() {
    if (_syncTrigger != null) {
      // TODO: what if sync is running and database will be deleted?
      _logger.d('Stopping sync timer...');
      _syncTrigger!.cancel();
      _syncTrigger = null;
    }
  }

  DateTime? get lastSync => _box.get(Keys.lastSync);

  Timer? _syncTrigger;

  bool get isSyncing => _isSyncing;

  bool _isSyncing;

  final _logger = Logger('Sync');
  late final Box<DateTime> _box;
  Sync._() : _isSyncing = false;

  void _setLastSync(DateTime dateTime) {
    _logger.i('Setting last sync to $dateTime...');
    _box.put(Keys.lastSync, dateTime);
  }

  void _removeLastSync() {
    _logger.i('Removing last sync...');
    _box.delete(Keys.lastSync);
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

  Future<void> _upSync() async {
    final now = DateTime.now();
    for (final db in allDataProviders) {
      // TODO: this can be sped up
      await db.pushToServer();
    }
    // TODO: upsync routes, cardio sessions, metcon sessions, movement muscle, training plan, metcon item, strength blueprint, cardio blueprint
    // TODO: deal with user updates
    _logger.i('Up sync: ${DateTime.now().difference(now)}');
  }

  Future<void> _downSync() async {
    final now = DateTime.now();
    final accountDataResult = await Api.instance.accountData.get(lastSync);
    if (accountDataResult.isFailure) {
      if (accountDataResult.failure == ApiError.noInternetConnection) {
        _logger.i('Tried down sync, but got no internet connection.');
      } else {
        _logger.e('Tried down sync, but got error.', accountDataResult.failure);
      }
      return;
    }
    final accountData = accountDataResult.success;
    for (final db in allDataProviders) {
      // TODO: this can be sped up
      await db.upsertPartOfAccountData(accountData);
    }
    // TODO: downsync routes, cardio sessions, metcon sessions, movement muscle, training plan, metcon item, strength blueprint, cardio blueprint
    // TODO: deal with user updates
    _logger.i('Down sync: ${DateTime.now().difference(now)}');
  }
}
