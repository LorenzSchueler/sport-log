import 'package:shared_preferences/shared_preferences.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/defs.dart';
import 'package:sport_log/helpers/logger.dart';

final _logger = Logger('SYNC');

class DownSync {
  static DownSync? _instance;
  static Future<DownSync> get instance async =>
      _instance ??= DownSync._(await SharedPreferences.getInstance());

  DownSync._(this._storage);

  final SharedPreferences _storage;

  Future<void> sync() async {
    final api = await Api.instance;
    final lastSync = await _lastSync();
    _storage.setString(Keys.lastSync, DateTime.now().toString());
    final result = await api.getAccountData(lastSync);
    if (result.isFailure) {
      // TODO: what to do now?
      _logger.w('Could not fetch account data');
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
}

class UpSync {
  static UpSync? _instance;
  static Future<UpSync> get instance async =>
      _instance ??= UpSync._(await SharedPreferences.getInstance());

  UpSync._(this._storage);

  final SharedPreferences _storage;

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
