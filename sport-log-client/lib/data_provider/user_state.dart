import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/user/user.dart';
import 'package:sport_log/settings.dart';

final _logger = Logger('USER STATE');

class UserState {
  static final instance = UserState._();
  UserState._();

  Future<void> init() async {
    _user = _getUser();
  }

  User? _user;

  User? get currentUser => _user;

  Future<void> deleteUser() async {
    _logger.i("deleting user data from storage...");
    Settings.instance.userId = null;
    Settings.instance.username = null;
    Settings.instance.password = null;
    Settings.instance.email = null;
    _user = null;
  }

  Future<void> setUser(User user) async {
    _logger.i("saving user data in storage...");
    Settings.instance.userId = user.id;
    Settings.instance.username = user.username;
    Settings.instance.password = user.password;
    Settings.instance.email = user.email;
    _user = user;
  }

  User? _getUser() {
    var id = Settings.instance.userId;
    var username = Settings.instance.username;
    var password = Settings.instance.password;
    var email = Settings.instance.email;
    if (id != null && username != null && password != null && email != null) {
      _logger.i("user data found");
      return User(id: id, username: username, password: password, email: email);
    } else {
      _logger.i("no user data found");
      return null;
    }
  }
}
