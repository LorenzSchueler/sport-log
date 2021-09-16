import 'package:shared_preferences/shared_preferences.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/user/user.dart';

final _logger = Logger('USER STATE');

class UserState {
  static final instance = UserState._();
  UserState._();

  Future<void> init() async {
    _storage = await SharedPreferences.getInstance();
    _user = _getUser();
  }

  late final SharedPreferences _storage;
  User? _user;

  User? get currentUser => _user;

  Future<void> deleteUser() async {
    _logger.i("deleting user data from storage...");
    for (final key in User.allKeys) {
      _storage.remove(key);
    }
    _user = null;
  }

  Future<void> setUser(User user) async {
    _logger.i("saving user data in storage...");
    for (final entry in user.toMap().entries) {
      _storage.setString(entry.key, entry.value);
    }
    _user = user;
  }

  User? _getUser() {
    _logger.i("reading user data from storage...");
    final Map<String, String> userMap = {};
    for (final key in User.allKeys) {
      final value = _storage.getString(key);
      if (value != null) {
        userMap[key] = value;
      }
    }
    final user = User.fromMap(userMap);
    if (user == null) {
      _logger.i("no user data found");
    } else {
      _logger.i("user data found");
    }
    return user;
  }
}
