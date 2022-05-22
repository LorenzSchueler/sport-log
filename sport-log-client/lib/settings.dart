import 'package:fixnum/fixnum.dart';
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

class Settings {
  static final _logger = Logger('Settings');

  static Box? _storage;

  static const String _syncEnabled = "syncEnabled";
  static const String _serverUrl = "serverUrl";
  static const String _syncInterval = "syncInterval";
  static const String _lastSync = "lastSync";
  static const String _units = "units";
  static const String _weightIncrement = "weightIncrement";
  static const String _id = "id";
  static const String _username = "username";
  static const String _password = "password";
  static const String _email = "email";
  static const String _lastMapPosition = "lastMapPosition";
  static const String _lastGpsLatLng = "lastGpsLatLng";

  static Future<void> init({bool override = false}) async {
    Hive
      ..registerAdapter(DurationAdapter())
      ..registerAdapter(LatLngAdapter())
      ..registerAdapter(CameraPositionAdapter());
    _storage ??= await Hive.openBox<dynamic>("settings");
    await setDefaults(override: override);
  }

  static Future<void> setDefaults({bool override = false}) async {
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
    if (override) {
      await _storage!.delete(_id);
    }
    if (override) {
      await _storage!.delete(_username);
    }
    if (override) {
      await _storage!.delete(_password);
    }
    if (override) {
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
  }

  static Future<void> setDefaultServerUrl() async {
    await _storage!.put(
      _serverUrl,
      Config.instance.isAndroidEmulator
          ? Defaults.server.emulatorUrl
          : Config.instance.serverAddress,
    );
  }

  // Hive supports all primitive types, List, Map, DateTime and Uint8List

  static bool _getBool(String key) {
    return _storage!.get(key)! as bool;
  }

  //static int _getInt(String key) {
  //return _storage!.get(key)! as int;
  //}

  static double _getDouble(String key) {
    return _storage!.get(key)! as double;
  }

  static String _getString(String key) {
    return _storage!.get(key)! as String;
  }

  static DateTime? _getDateTimeOptional(String key) {
    return _storage!.get(key) as DateTime?;
  }

  static Duration _getDuration(String key) {
    return _storage!.get(key) as Duration;
  }

  static LatLng _getLatLng(String key) {
    return _storage!.get(key) as LatLng;
  }

  static CameraPosition _getCameraPosition(String key) {
    return _storage!.get(key) as CameraPosition;
  }

  static void _put(String key, dynamic value) {
    _storage!.put(key, value);
  }

  static bool get syncEnabled {
    return _getBool(_syncEnabled);
  }

  static set syncEnabled(bool enabled) {
    _put(_syncEnabled, enabled);
  }

  static String get serverUrl {
    return _getString(_serverUrl);
  }

  static set serverUrl(String url) {
    _put(_serverUrl, url);
  }

  static Duration get syncInterval {
    return _getDuration(_syncInterval);
  }

  static set syncInterval(Duration interval) {
    _put(_syncInterval, interval);
  }

  static DateTime? get lastSync {
    return _getDateTimeOptional(_lastSync);
  }

  static set lastSync(DateTime? lastSync) {
    _put(_lastSync, lastSync);
  }

  static Units get units {
    return Units.fromString(_getString(_units));
  }

  static set units(Units units) {
    _put(_units, units.name);
  }

  static double get weightIncrement {
    return _getDouble(_weightIncrement);
  }

  static set weightIncrement(double incement) {
    _put(_weightIncrement, incement);
  }

  static Int64? get userId {
    return userExists() ? Int64.parseInt(_getString(_id)) : null;
  }

  static set userId(Int64? id) {
    id == null ? _storage!.delete(_id) : _put(_id, id.toString());
  }

  static String? get username {
    return userExists() ? _getString(_username) : null;
  }

  static set username(String? username) {
    username == null ? _storage!.delete(_username) : _put(_username, username);
  }

  static String? get password {
    return userExists() ? _getString(_password) : null;
  }

  static set password(String? password) {
    password == null ? _storage!.delete(_password) : _put(_password, password);
  }

  static String? get email {
    return userExists() ? _getString(_email) : null;
  }

  static set email(String? email) {
    email == null ? _storage!.delete(_email) : _put(_email, email);
  }

  static bool userExists() {
    return _storage!.containsKey(_id);
  }

  static set user(User? user) {
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

  static User? get user {
    return userExists()
        ? User(
            id: userId!,
            username: username!,
            password: password!,
            email: email!,
          )
        : null;
  }

  static CameraPosition get lastMapPosition {
    return _getCameraPosition(_lastMapPosition);
  }

  static set lastMapPosition(CameraPosition latLng) {
    _put(_lastMapPosition, latLng);
  }

  static LatLng get lastGpsLatLng {
    return _getLatLng(_lastGpsLatLng);
  }

  static set lastGpsLatLng(LatLng latLng) {
    _put(_lastGpsLatLng, latLng);
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
