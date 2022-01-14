import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/user/user.dart';
import 'package:sport_log/settings.dart';

final _logger = Logger('USER STATE');

class UserState {
  static final instance = UserState._();
  UserState._();

  Future<void> init() async {
    _settings = await Settings.get();
    _user = _getUser();
  }

  late final Settings _settings;
  User? _user;

  User? get currentUser => _user;

  Future<void> deleteUser() async {
    _logger.i("deleting user data from storage...");
    _settings.userId = null;
    _settings.username = null;
    _settings.password = null;
    _settings.email = null;
    _user = null;
  }

  Future<void> setUser(User user) async {
    _logger.i("saving user data in storage...");
    _settings.userId = user.id;
    _settings.username = user.username;
    _settings.password = user.password;
    _settings.email = user.email;
    _user = user;
  }

  User? _getUser() {
    _logger.i("reading user data from storage...");
    var id = _settings.userId;
    var username = _settings.username;
    var password = _settings.password;
    var email = _settings.email;
    if (id != null && username != null && password != null && email != null) {
      _logger.i("user data found");
      return User(id: id, username: username, password: password, email: email);
    } else {
      _logger.i("no user data found");
      return null;
    }
  }
}
