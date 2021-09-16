import 'package:shared_preferences/shared_preferences.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/user_state.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/defs.dart';
import 'package:sport_log/helpers/logger.dart';

final _logger = Logger('SYNC');

class DownSync {
  static final DownSync instance = DownSync._();
  DownSync._();

  Future<DownSync> init() async {
    _storage = await SharedPreferences.getInstance();
    return this;
  }

  late final SharedPreferences _storage;

  Future<void> sync() async {
    if (UserState.instance.currentUser == null) {
      return;
    }
    final api = Api.instance;
    final lastSync = await _lastSync();
    _storage.setString(Keys.lastSync, DateTime.now().toString());
    final result = await api.accountData.get(lastSync);
    if (result.isFailure) {
      // TODO: what to do now?
      _logger.w(
          'Could not fetch account data: ${result.failure.toErrorMessage()}');
      return;
    }
    final db = AppDatabase.instance;
    if (db == null) {
      // TODO: syncing on the web?
      return;
    }
    db
        .upsertAccountData(result.success)
        .then((_) => _logger.i('down sync done'));
    // TODO: handle user update
  }

  Future<DateTime?> _lastSync() async {
    final result = _storage.getString(Keys.lastSync);
    return result == null ? null : DateTime.parse(result);
  }

  Future<void> removeLastSync() async {
    _logger.d('Deleting last sync datetime...');
    await _storage.remove(Keys.lastSync);
  }
}

class UpSync {
  static UpSync instance = UpSync._();
  UpSync._();

  Future<void> init() async {
    _storage = await SharedPreferences.getInstance();
  }

  late final SharedPreferences _storage;

  Future<void> syncNeeded() async {
    _storage.setBool(Keys.syncNeeded, true);
  }

  Future<bool> get isSyncNeeded async =>
      _storage.getBool(Keys.syncNeeded) ?? false;

  Future<void> sync() async {
    if (!await isSyncNeeded) {
      return;
    }
    // TODO: check for internet connection
    _pushToServer();
    _storage.setBool(Keys.syncNeeded, false);
  }

  Future<void> _pushToServer() async {
    final db = AppDatabase.instance;
    if (db == null) {
      return;
    }
    final api = Api.instance;

    // TODO: push database records and changed user
    throw UnimplementedError();
  }
}
