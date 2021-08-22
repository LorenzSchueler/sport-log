
import 'dart:developer';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sport_log/models/user/user.dart';

class AuthenticationRepository {
  AuthenticationRepository._(this._storage);

  static Future<AuthenticationRepository> getInstance() async {
   return AuthenticationRepository._(await SharedPreferences.getInstance());
  }

  final SharedPreferences _storage;
  static const String _debugName = "auth repo";

 Future<void> deleteUser() async {
  log("deleting user data from storage...", name: _debugName);
  for (final key in User.allKeys) {
   _storage.remove(key);
  }
 }

 Future<void> createUser(User user) async {
  log("saving user data in storage...", name: _debugName);
  for (final entry in user.toMap().entries) {
   _storage.setString(entry.key, entry.value);
  }
 }

 Future<User?> getUser() async {
  log("reading user data from storage...", name: _debugName);
  final Map<String, String> userMap = {};
  for (final key in User.allKeys) {
    final value = _storage.getString(key);
    if (value != null) {
      userMap[key] = value;
    }
  }
  final user = User.fromMap(userMap);
  if (user == null) {
   log("no user data found", name: _debugName);
  } else {
   log("user data found", name: _debugName);
  }
  return user;
 }
}