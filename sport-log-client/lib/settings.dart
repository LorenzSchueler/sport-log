import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/expedition_tracking_utils.dart';
import 'package:sport_log/helpers/lat_lng.dart';
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

  static Box<Object?>? _storage;

  static const String _accountCreated = "accountCreated";
  static const String _syncEnabled = "syncEnabled";
  static const String _serverUrl = "serverUrl";
  static const String _syncInterval = "syncInterval";
  static const String _lastSync = "lastSync";
  static const String _checkForUpdates = "checkForUpdates";
  static const String _units = "units";
  static const String _weightIncrement = "weightIncrement";
  static const String _durationIncrement = "durationIncrement";
  static const String _id = "id";
  static const String _username = "username";
  static const String _password = "password";
  static const String _email = "email";
  static const String _lastMapPosition = "lastMapPosition";
  static const String _lastGpsLatLng = "lastGpsLatLng";
  static const String _expeditionData = "expeditionData";
  static const String _developer = "developer";

  static const Duration _defaultSyncInterval = Duration(minutes: 5);

  Future<void> init({bool override = false}) async {
    Hive
      ..registerAdapter(DurationAdapter())
      ..registerAdapter(LatLngAdapter())
      ..registerAdapter(CameraPositionAdapter())
      ..registerAdapter(TimeOfDayAdapter())
      ..registerAdapter(Int64Adapter())
      ..registerAdapter(ExpeditionDataAdapter());
    _storage ??= await Hive.openBox(Config.hiveBoxName);
    await _setDefaults(override: override);
  }

  // ignore: long-method
  Future<void> _setDefaults({bool override = false}) async {
    // do not use _put to avoid calling notifyListeners repeatedly.
    if (!_contains(_accountCreated) || override) {
      await _storage!.put(_accountCreated, false);
    }
    if (!_contains(_syncEnabled) || override) {
      await _storage!.put(_syncEnabled, true);
    }
    if (!_contains(_serverUrl) || override) {
      await setDefaultServerUrl();
    }
    if (!_contains(_syncInterval) || override) {
      await _storage!.put(_syncInterval, _defaultSyncInterval);
    }
    if (!_contains(_lastSync) || override) {
      await _storage!.put(_lastSync, null);
    }
    if (!_contains(_checkForUpdates) || override) {
      await _storage!.put(_checkForUpdates, true);
    }
    if (!_contains(_units) || override) {
      await _storage!.put(_units, "metric");
    }
    if (!_contains(_weightIncrement) || override) {
      await _storage!.put(_weightIncrement, 2.5);
    }
    if (!_contains(_durationIncrement) || override) {
      await _storage!.put(_durationIncrement, const Duration(minutes: 1));
    }
    if (!_contains(_id) || override) {
      await _storage!.put(_id, null);
    }
    if (_storage!.get(_id) is String?) {
      // upgrade: _id had been stored as String? in past
      await _storage!
          .put(_id, Int64.tryParseInt(_storage!.get(_id) as String? ?? ""));
    }
    if (!_contains(_username) || override) {
      await _storage!.put(_username, null);
    }
    if (!_contains(_password) || override) {
      await _storage!.put(_password, null);
    }
    if (!_contains(_email) || override) {
      await _storage!.put(_email, null);
    }
    if (!_contains(_lastMapPosition) || override) {
      await _storage!.put(
        _lastMapPosition,
        LatLngZoom(latLng: Defaults.mapbox.cameraPosition, zoom: 12),
      );
    }
    if (!_contains(_lastGpsLatLng) || override) {
      await _storage!.put(_lastGpsLatLng, Defaults.mapbox.cameraPosition);
    }
    if (!_contains(_expeditionData) || override) {
      await _storage!.put(_expeditionData, null);
    }
    if (!_contains(_developer) || override) {
      await _storage!.put(_developer, false);
    }
    notifyListeners();
  }

  String getDefaultServerUrl() => Config.instance.isAndroidEmulator
      ? Defaults.server.emulatorUrl
      : Config.instance.serverAddress;

  Future<void> setDefaultServerUrl() => _put(_serverUrl, getDefaultServerUrl());

  bool _contains(String key) => _storage!.containsKey(key);

  // Hive supports all primitive types, List, Map, DateTime and Uint8List

  bool _getBool(String key) => _storage!.get(key)! as bool;

  double _getDouble(String key) => _storage!.get(key)! as double;

  String _getString(String key) => _storage!.get(key)! as String;

  String? _getStringOptional(String key) => _storage!.get(key) as String?;

  DateTime? _getDateTimeOptional(String key) => _storage!.get(key) as DateTime?;

  Duration _getDuration(String key) => _storage!.get(key)! as Duration;

  LatLng _getLatLng(String key) => _storage!.get(key)! as LatLng;

  LatLngZoom _getLatLngZoom(String key) => _storage!.get(key)! as LatLngZoom;

  Int64? _getInt64Optional(String key) => _storage!.get(key) as Int64?;

  ExpeditionData? _getExpeditionDataOptional(String key) =>
      _storage!.get(key) as ExpeditionData?;

  Future<void> _put(String key, Object? value) async {
    await _storage!.put(key, value);
    notifyListeners();
  }

  bool get accountCreated => _getBool(_accountCreated);

  Future<void> setAccountCreated(bool created) =>
      _put(_accountCreated, created);

  bool get syncEnabled => _getBool(_syncEnabled);

  Future<void> setSyncEnabled(bool enabled) => _put(_syncEnabled, enabled);

  String get serverUrl => _getString(_serverUrl);

  Future<void> setServerUrl(String url) => _put(_serverUrl, url);

  Duration get syncInterval => _getDuration(_syncInterval);

  Future<void> setSyncInterval(Duration interval) =>
      _put(_syncInterval, interval);

  Future<void> setDefaultSyncInterval() =>
      _put(_syncInterval, _defaultSyncInterval);

  DateTime? get lastSync => _getDateTimeOptional(_lastSync);

  Future<void> setLastSync(DateTime? lastSync) => _put(_lastSync, lastSync);

  bool get checkForUpdates => _getBool(_checkForUpdates);

  Future<void> setCheckForUpdates(bool checkForUpdates) =>
      _put(_checkForUpdates, checkForUpdates);

  Units get units => Units.fromString(_getString(_units));

  Future<void> setUnits(Units units) => _put(_units, units.name);

  double get weightIncrement => _getDouble(_weightIncrement);

  Future<void> setWeightIncrement(double increment) =>
      _put(_weightIncrement, increment);

  Duration get durationIncrement => _getDuration(_durationIncrement);

  Future<void> setDurationIncrement(Duration increment) =>
      _put(_durationIncrement, increment);

  Int64? get userId => _getInt64Optional(_id);

  Future<void> setUserId(Int64? id) => _put(_id, id);

  String? get username => _getStringOptional(_username);

  Future<void> setUsername(String? username) => _put(_username, username);

  String? get password => _getStringOptional(_password);

  Future<void> setPassword(String? password) => _put(_password, password);

  String? get email => _getStringOptional(_email);

  Future<void> setEmail(String? email) => _put(_email, email);

  bool userExists() =>
      userId != null && username != null && password != null && email != null;

  Future<void> setUser(User? user) async {
    if (user == null) {
      await setUserId(null);
      await setUsername(null);
      await setPassword(null);
      await setEmail(null);
      _logger.d("user deleted");
    } else {
      await setUserId(user.id);
      await setUsername(user.username);
      await setPassword(user.password);
      await setEmail(user.email);
      _logger.d("user updated");
    }
  }

  User? get user => userExists()
      ? User(
          id: userId!,
          username: username!,
          password: password!,
          email: email!,
        )
      : null;

  LatLngZoom get lastMapPosition => _getLatLngZoom(_lastMapPosition);

  Future<void> setLastMapPosition(LatLngZoom latLng) =>
      _put(_lastMapPosition, latLng);

  LatLng get lastGpsLatLng => _getLatLng(_lastGpsLatLng);

  Future<void> setLastGpsLatLng(LatLng latLng) => _put(_lastGpsLatLng, latLng);

  ExpeditionData? get expeditionData =>
      _getExpeditionDataOptional(_expeditionData);

  Future<void> setExpeditionData(ExpeditionData? id) =>
      _put(_expeditionData, id);

  bool get developerMode => _getBool(_developer);

  Future<void> setDeveloperMode(bool developerMode) =>
      _put(_developer, developerMode);
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
    return LatLng(lat: values[0], lng: values[1]);
  }

  @override
  void write(BinaryWriter writer, LatLng obj) {
    writer.writeDoubleList([obj.lat, obj.lng]);
  }
}

class CameraPositionAdapter extends TypeAdapter<LatLngZoom> {
  @override
  final typeId = 2;

  @override
  LatLngZoom read(BinaryReader reader) {
    final values = reader.readDoubleList();
    return LatLngZoom(
      zoom: values[0],
      latLng: LatLng(lat: values[1], lng: values[2]),
    );
  }

  @override
  void write(BinaryWriter writer, LatLngZoom obj) {
    writer.writeDoubleList([obj.zoom, obj.latLng.lat, obj.latLng.lng]);
  }
}

class TimeOfDayAdapter extends TypeAdapter<TimeOfDay> {
  @override
  final typeId = 3;

  @override
  TimeOfDay read(BinaryReader reader) {
    final values = reader.readIntList();
    return TimeOfDay(hour: values[0], minute: values[1]);
  }

  @override
  void write(BinaryWriter writer, TimeOfDay obj) {
    writer.writeIntList([obj.hour, obj.minute]);
  }
}

class Int64Adapter extends TypeAdapter<Int64> {
  @override
  final typeId = 4;

  @override
  Int64 read(BinaryReader reader) {
    final value = reader.readString();
    return Int64.parseInt(value);
  }

  @override
  void write(BinaryWriter writer, Int64 obj) {
    writer.writeString(obj.toString());
  }
}

class ExpeditionDataAdapter extends TypeAdapter<ExpeditionData> {
  @override
  final int typeId = 5;

  @override
  ExpeditionData read(BinaryReader reader) {
    return ExpeditionData(
      cardioId: reader.read() as Int64,
      trackingTimes: reader.readList().cast<TimeOfDay>(),
    );
  }

  @override
  void write(BinaryWriter writer, ExpeditionData obj) {
    writer
      ..write(obj.cardioId)
      ..writeList(obj.trackingTimes);
  }
}
