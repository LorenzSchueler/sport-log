import 'package:fixnum/fixnum.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Units { metric, imperial }

extension UnitsFromString on Units {
  static Units fromString(String unitString) {
    return Units.values.firstWhere((value) => value.name == unitString);
  }
}

class Settings {
  static final instance = Settings._();
  Settings._();

  SharedPreferences? _storage;

  static Future<void> init() async {
    await Settings.instance._setDefaults();
  }

  Future<void> _setDefaults() async {
    if (_storage == null) {
      _storage = await SharedPreferences.getInstance();
      _storage!.getBool("serverEnabled") ??
          _storage!.setBool("serverEnabled", true);
      _storage!.getString("serverUrl") ??
          _storage!.setString("serverUrl", "<default URL>"); // TODO
      _storage!.getInt("syncInterval") ?? _storage!.setInt("syncInterval", 300);
      _storage!.getString("units") ?? _storage!.setString("units", "metric");
    }
  }

  bool get serverEnabled {
    return _storage!.getBool("serverEnabled")!;
  }

  set serverEnabled(bool enabled) {
    _storage!.setBool("serverEnabled", enabled);
  }

  String get serverUrl {
    return _storage!.getString("serverUrl")!;
  }

  set serverUrl(String url) {
    _storage!.setString("serverUrl", url);
  }

  Duration get syncInterval {
    return Duration(seconds: _storage!.getInt("syncInterval")!);
  }

  set syncInterval(Duration interval) {
    _storage!.setInt("syncInterval", interval.inSeconds);
  }

  Units get units {
    return UnitsFromString.fromString(_storage!.getString("units")!);
  }

  set units(Units units) {
    _storage!.setString("units", units.name);
  }

  Int64? get userId {
    var id = _storage!.getString("id");
    if (id == null) {
      return null;
    } else {
      return Int64.parseInt(id);
    }
  }

  set userId(Int64? id) {
    if (id == null) {
      _storage!.remove("id");
    } else {
      _storage!.setString("id", id.toString());
    }
  }

  String? get username {
    return _storage!.getString("username");
  }

  set username(String? username) {
    if (username == null) {
      _storage!.remove("username");
    } else {
      _storage!.setString("username", username);
    }
  }

  String? get password {
    return _storage!.getString("password");
  }

  set password(String? password) {
    if (password == null) {
      _storage!.remove("password");
    } else {
      _storage!.setString("password", password);
    }
  }

  String? get email {
    return _storage!.getString("email");
  }

  set email(String? email) {
    if (email == null) {
      _storage!.remove("email");
    } else {
      _storage!.setString("email", email);
    }
  }
}
