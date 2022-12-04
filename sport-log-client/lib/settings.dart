import 'package:fixnum/fixnum.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/user/user.dart';

enum Units {
  metric,
  imperial;

  static Units fromString(String unitString) {
    return Units.values.firstWhere((value) => value.name == unitString);
  }
}

class Settings extends ChangeNotifier {
  Settings._();

  static final Settings instance = Settings._();

  static final _logger = Logger('Settings');

  static Box? _storage;

  static const String _accountCreated = "accountCreated";
  static const String _syncEnabled = "syncEnabled";
  static const String _serverUrl = "serverUrl";
  static const String _syncInterval = "syncInterval";
  static const String _lastSync = "lastSync";
  static const String _units = "units";
  static const String _weightIncrement = "weightIncrement";
  static const String _durationIncrement = "durationIncrement";
  static const String _id = "id";
  static const String _username = "username";
  static const String _password = "password";
  static const String _email = "email";
  static const String _lastMapPosition = "lastMapPosition";
  static const String _lastGpsLatLng = "lastGpsLatLng";
  static const String _developer = "developer";

  Future<void> init({bool override = false}) async {
    Hive
      ..registerAdapter(DurationAdapter())
      ..registerAdapter(LatLngAdapter())
      ..registerAdapter(CameraPositionAdapter());
    _storage ??= await Hive.openBox<dynamic>(Config.hiveBoxName);
    await setDefaults(override: override);
  }

  Future<void> setDefaults({bool override = false}) async {
    if (!_storage!.containsKey(_accountCreated) || override) {
      await _storage!.put(_accountCreated, true);
    }
    if (!_storage!.containsKey(_syncEnabled) || override) {
      await _storage!.put(_syncEnabled, true);
    }
    if (!_storage!.containsKey(_serverUrl) || override) {
      await setDefaultServerUrl();
    }
    if (!_storage!.containsKey(_syncInterval) || override) {
      await _storage!.put(_syncInterval, const Duration(minutes: 5));
    }
    if (override) {
      await _storage!.delete(_lastSync);
    }
    if (!_storage!.containsKey(_units) || override) {
      await _storage!.put(_units, "metric");
    }
    if (!_storage!.containsKey(_weightIncrement) || override) {
      await _storage!.put(_weightIncrement, 2.5);
    }
    if (!_storage!.containsKey(_durationIncrement) || override) {
      await _storage!.put(_durationIncrement, const Duration(minutes: 1));
    }
    if (override) {
      await _storage!.delete(_id);
      await _storage!.delete(_username);
      await _storage!.delete(_password);
      await _storage!.delete(_email);
    }
    if (!_storage!.containsKey(_lastMapPosition) || override) {
      await _storage!.put(
        _lastMapPosition,
        CameraPosition(target: Defaults.mapbox.cameraPosition),
      );
    }
    if (!_storage!.containsKey(_lastGpsLatLng) || override) {
      await _storage!.put(_lastGpsLatLng, Defaults.mapbox.cameraPosition);
    }
    if (!_storage!.containsKey(_developer) || override) {
      await _storage!.put(_developer, false);
    }
  }

  Future<String> setDefaultServerUrl() async {
    final url = Config.instance.isAndroidEmulator
        ? Defaults.server.emulatorUrl
        : Config.instance.serverAddress;
    await _storage!.put(_serverUrl, url);
    return url;
  }

  // Hive supports all primitive types, List, Map, DateTime and Uint8List

  bool _getBool(String key) {
    return _storage!.get(key)! as bool;
  }

  double _getDouble(String key) {
    return _storage!.get(key)! as double;
  }

  String _getString(String key) {
    return _storage!.get(key)! as String;
  }

  DateTime? _getDateTimeOptional(String key) {
    return _storage!.get(key) as DateTime?;
  }

  Duration _getDuration(String key) {
    return _storage!.get(key) as Duration;
  }

  LatLng _getLatLng(String key) {
    return _storage!.get(key) as LatLng;
  }

  CameraPosition _getCameraPosition(String key) {
    return _storage!.get(key) as CameraPosition;
  }

  Future<void> _put(String key, dynamic value) async {
    await _storage!.put(key, value);
    notifyListeners();
  }

  bool get accountCreated {
    return _getBool(_accountCreated);
  }

  set accountCreated(bool created) {
    _put(_accountCreated, created);
  }

  bool get syncEnabled {
    return _getBool(_syncEnabled);
  }

  set syncEnabled(bool enabled) {
    _put(_syncEnabled, enabled);
  }

  String get serverUrl {
    return _getString(_serverUrl);
  }

  set serverUrl(String url) {
    _put(_serverUrl, url);
  }

  Duration get syncInterval {
    return _getDuration(_syncInterval);
  }

  set syncInterval(Duration interval) {
    _put(_syncInterval, interval);
  }

  DateTime? get lastSync {
    return _getDateTimeOptional(_lastSync);
  }

  set lastSync(DateTime? lastSync) {
    _put(_lastSync, lastSync);
  }

  Units get units {
    return Units.fromString(_getString(_units));
  }

  set units(Units units) {
    _put(_units, units.name);
  }

  double get weightIncrement {
    return _getDouble(_weightIncrement);
  }

  set weightIncrement(double increment) {
    _put(_weightIncrement, increment);
  }

  Duration get durationIncrement {
    return _getDuration(_durationIncrement);
  }

  set durationIncrement(Duration increment) {
    _put(_durationIncrement, increment);
  }

  Int64? get userId {
    return userExists() ? Int64.parseInt(_getString(_id)) : null;
  }

  set userId(Int64? id) {
    id == null ? _storage!.delete(_id) : _put(_id, id.toString());
    notifyListeners();
  }

  String? get username {
    return userExists() ? _getString(_username) : null;
  }

  set username(String? username) {
    username == null ? _storage!.delete(_username) : _put(_username, username);
    notifyListeners();
  }

  String? get password {
    return userExists() ? _getString(_password) : null;
  }

  set password(String? password) {
    password == null ? _storage!.delete(_password) : _put(_password, password);
    notifyListeners();
  }

  String? get email {
    return userExists() ? _getString(_email) : null;
  }

  set email(String? email) {
    email == null ? _storage!.delete(_email) : _put(_email, email);
    notifyListeners();
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
    return userExists()
        ? User(
            id: userId!,
            username: username!,
            password: password!,
            email: email!,
          )
        : null;
  }

  CameraPosition get lastMapPosition {
    return _getCameraPosition(_lastMapPosition);
  }

  set lastMapPosition(CameraPosition latLng) {
    _put(_lastMapPosition, latLng);
  }

  LatLng get lastGpsLatLng {
    return _getLatLng(_lastGpsLatLng);
  }

  set lastGpsLatLng(LatLng latLng) {
    _put(_lastGpsLatLng, latLng);
  }

  bool get developerMode {
    return _getBool(_developer);
  }

  set developerMode(bool developerMode) {
    _put(_developer, developerMode);
  }
}

class DurationAdapter extends TypeAdapter<Duration> {
  @override
  final typeId = 0;

  @override
  Duration read(BinaryReader reader) {
    return Duration(milliseconds: reader.readInt());
  }

  @override
  void write(BinaryWriter writer, Duration obj) {
    writer.writeInt(obj.inMilliseconds);
  }
}

class LatLngAdapter extends TypeAdapter<LatLng> {
  @override
  final typeId = 1;

  @override
  LatLng read(BinaryReader reader) {
    final values = reader.readDoubleList();
    return LatLng(values[0], values[1]);
  }

  @override
  void write(BinaryWriter writer, LatLng obj) {
    writer.writeDoubleList([obj.latitude, obj.longitude]);
  }
}

class CameraPositionAdapter extends TypeAdapter<CameraPosition> {
  @override
  final typeId = 2;

  @override
  CameraPosition read(BinaryReader reader) {
    final values = reader.readDoubleList();
    return CameraPosition(
      zoom: values[0],
      target: LatLng(values[1], values[2]),
    );
  }

  @override
  void write(BinaryWriter writer, CameraPosition obj) {
    writer.writeDoubleList(
      [obj.zoom, obj.target.latitude, obj.target.longitude],
    );
  }
}
