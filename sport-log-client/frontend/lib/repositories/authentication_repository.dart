
import 'package:sport_log/models/user.dart';

class AuthenticationRepository {
 User? _user;

 Future<void> deleteUser() {
  return Future.delayed(
   const Duration(milliseconds: 300), () {
    _user = null;
   }
  );
 }

 Future<void> createUser(User user) {
  return Future.delayed(
   const Duration(milliseconds: 300), () {
    _user = user;
   }
  );
 }
}