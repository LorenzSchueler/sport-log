
import 'dart:developer';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sport_log/models/user.dart';

class AuthenticationRepository {

  final storage = const FlutterSecureStorage();

 Future<void> deleteUser() async {
  log("deleting user data from secure storage...");
  for (final key in User.allKeys) {
   storage.delete(key: key);
  }
 }

 Future<void> createUser(User user) async {
  log("saving user data in secure storage...");
  for (final entry in user.toMap().entries) {
   storage.write(key: entry.key, value: entry.value);
  }
 }

 Future<User?> getUser() async {
  log("reading user data from secure storage...");
  final user = User.fromMap(await storage.readAll());
  if (user == null) {
   log("no user data found");
  } else {
   log("user data found");
  }
  return user;
 }
}