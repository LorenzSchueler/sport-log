
import 'package:equatable/equatable.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.username,
    required this.password,
    required this.email,
  }) : super();

  final int id;
  final String username;
  final String password;
  final String email;

  @override
  List<Object?> get props => [id, username, password, email];

  static const String idKey = "id";
  static const String usernameKey = "username";
  static const String passwordKey = "password";
  static const String emailKey = "email";

  static const List<String> allKeys = [idKey, usernameKey, passwordKey, emailKey];

  Map<String, String> toMap() => {
    idKey: id.toString(),
    usernameKey: username,
    passwordKey: password,
    emailKey: email,
  };

  static User? fromMap(Map<String, String> map) {
    if (map.containsKey(idKey) && map.containsKey(usernameKey)
      && map.containsKey(passwordKey) && map.containsKey(emailKey)) {
      final id = int.tryParse(map[idKey]!);
      if (id == null) {
        return null;
      }
      return User(
          id: id,
          username: map[usernameKey]!,
          password: map[passwordKey]!,
          email: map[emailKey]!
      );
    }
    return null;
  }
}