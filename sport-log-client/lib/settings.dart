import 'package:fixnum/fixnum.dart';
import 'package:hive/hive.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/user/user.dart';

enum Units { metric, imperial }

extension UnitsFromString on Units {
  static Units fromString(String unitString) {
    return Units.values.firstWhere((value) => value.name == unitString);
  }
}

class Settings {
  final _logger = Logger('Settings');

  static final instance = Settings._();
  Settings._();

  Box? _storage;

  static const String _serverEnabled = "serverEnabled";
  static const String _serverUrl = "serverUrl";
  static const String _syncInterval = "syncInterval";
  static const String _lastSync = "lastSync";
  static const String _units = "units";
  static const String _id = "id";
  static const String _username = "username";
  static const String _password = "password";
  static const String _email = "email";

  static Future<void> init() async {
    await Settings.instance._setDefaults();
  }

  Future<void> _setDefaults() async {
    if (_storage == null) {
      _storage = await Hive.openBox<dynamic>("settings");
      if (!_storage!.containsKey(_serverEnabled)) {
        _storage!.put(_serverEnabled, true);
      }
      if (!_storage!.containsKey(_serverUrl)) {
        await setDefaultServerUrl();
      }
      if (!_storage!.containsKey(_syncInterval)) {
        _storage!.put(_syncInterval, 300);
      }
      if (!_storage!.containsKey(_units)) {
        _storage!.put(_units, "metric");
      }
    }
  }

  Future<void> setDefaultServerUrl() async {
    _storage!.put(
        _serverUrl,
        await Config.isAndroidEmulator
            ? Defaults.server.emulatorUrl
            : Defaults.server.url);
  }

  bool _getBool(String key) {
    return _storage!.get(key)! as bool;
  }

  int _getInt(String key) {
    return _storage!.get(key)! as int;
  }

  String _getString(String key) {
    return _storage!.get(key)! as String;
  }

  DateTime? _getDateTimeOptional(String key) {
    return _storage!.get(key) as DateTime?;
  }

  void _put(String key, dynamic value) {
    _storage!.put(key, value);
  }

  bool get serverEnabled {
    return _getBool(_serverEnabled);
  }

  set serverEnabled(bool enabled) {
    _put(_serverEnabled, enabled);
  }

  String get serverUrl {
    return _getString(_serverUrl);
  }

  set serverUrl(String url) {
    _put(_serverUrl, url);
  }

  Duration get syncInterval {
    return Duration(seconds: _getInt(_syncInterval));
  }

  set syncInterval(Duration interval) {
    _put(_syncInterval, interval.inSeconds);
  }

  DateTime? get lastSync {
    return _getDateTimeOptional(_lastSync);
  }

  set lastSync(DateTime? lastSync) {
    _put(_lastSync, lastSync);
  }

  Units get units {
    return UnitsFromString.fromString(_getString(_units));
  }

  set units(Units units) {
    _put(_units, units.name);
  }

  Int64? get userId {
    return userExists() ? Int64.parseInt(_getString(_id)) : null;
  }

  set userId(Int64? id) {
    id == null ? _storage!.delete(_id) : _put(_id, id.toString());
  }

  String? get username {
    return userExists() ? _getString(_username) : null;
  }

  set username(String? username) {
    username == null ? _storage!.delete(_username) : _put(_username, username);
  }

  String? get password {
    return userExists() ? _getString(_password) : null;
  }

  set password(String? password) {
    password == null ? _storage!.delete(_password) : _put(_password, password);
  }

  String? get email {
    return userExists() ? _getString(_email) : null;
  }

  set email(String? email) {
    email == null ? _storage!.delete(_email) : _put(_email, email);
  }

  bool userExists() {
    return _storage!.containsKey(_id);
  }

  set user(User? user) {
    if (user == null) {
      userId = null;
      username = null;
      password = null;
      email = null;
      _logger.i("user deleted");
    } else {
      userId = user.id;
      username = user.username;
      password = user.password;
      email = user.email;
      _logger.i("user updated");
    }
  }

  User? get user {
    if (userExists()) {
      _logger.i("user data found");
      return User(
          id: userId!, username: username!, password: password!, email: email!);
    } else {
      _logger.i("no user data found");
      return null;
    }
  }
}
