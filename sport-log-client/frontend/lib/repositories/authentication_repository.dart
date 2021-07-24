
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sport_log/models/user.dart';

class AuthenticationRepository {

  final storage = const FlutterSecureStorage();

 Future<void> deleteUser() async {
  for (final key in User.allKeys) {
   storage.delete(key: key);
  }
 }

 Future<void> createUser(User user) async {
  for (final entry in user.toMap().entries) {
   storage.write(key: entry.key, value: entry.value);
  }
 }

 Future<User?> getUser() async {
  return User.fromMap(await storage.readAll());
 }
}