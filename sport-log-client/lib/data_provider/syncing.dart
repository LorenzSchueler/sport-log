import 'package:shared_preferences/shared_preferences.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/user_state.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/keys.dart';
import 'package:sport_log/helpers/logger.dart';

final _logger = Logger('SYNC');

class DownSync {
  static final DownSync instance = DownSync._();
  DownSync._();

  Future<DownSync> init() async {
    _storage = await SharedPreferences.getInstance();
    _lastSync = await _readLastSync();
    return this;
  }

  late final SharedPreferences _storage;
  late DateTime? _lastSync;

  DateTime? get lastSync => _lastSync;

  Future<void> sync() async {
    if (UserState.instance.currentUser == null) {
      return;
    }
    final api = Api.instance;
    final oldLastSync = _lastSync;
    final newLastSync = DateTime.now();
    final result = await api.accountData.get(oldLastSync);
    if (result.isFailure) {
      // TODO: what to do now?
      _logger.w(
          'Could not fetch account data: ${result.failure.toErrorMessage()}');
      return;
    }
    _writeLastSync(newLastSync);
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

  Future<void> _writeLastSync(DateTime dateTime) async {
    _lastSync = dateTime;
    _storage.setString(Keys.lastSync, dateTime.toString());
  }

  Future<DateTime?> _readLastSync() async {
    final result = _storage.getString(Keys.lastSync);
    return result == null ? null : DateTime.parse(result);
  }

  Future<void> removeLastSync() async {
    _logger.d('Deleting last sync datetime...');
    _lastSync = null;
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
    // TODO: push database records and changed user
    throw UnimplementedError();
  }
}
