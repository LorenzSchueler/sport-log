
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/user/user.dart';

class AuthenticationRepository {
  AuthenticationRepository._(this._storage);

  static Future<AuthenticationRepository> getInstance() async {
   return AuthenticationRepository._(await SharedPreferences.getInstance());
  }

  final SharedPreferences _storage;

 Future<void> deleteUser() async {
  logger.i("deleting user data from storage...");
  for (final key in User.allKeys) {
   _storage.remove(key);
  }
 }

 Future<void> createUser(User user) async {
  logger.i("saving user data in storage...");
  for (final entry in user.toMap().entries) {
   _storage.setString(entry.key, entry.value);
  }
 }

 Future<User?> getUser() async {
  logger.i("reading user data from storage...");
  final Map<String, String> userMap = {};
  for (final key in User.allKeys) {
    final value = _storage.getString(key);
    if (value != null) {
      userMap[key] = value;
    }
  }
  final user = User.fromMap(userMap);
  if (user == null) {
   logger.i("no user data found");
  } else {
   logger.i("user data found");
  }
  return user;
 }
}