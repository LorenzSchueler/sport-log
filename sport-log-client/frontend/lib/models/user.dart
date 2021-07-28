
import 'package:equatable/equatable.dart';

abstract class Keys {
  static const usernameKey = 'username';
  static const passwordKey = 'password';
  static const emailKey = 'email';
  static const idKey = 'id';
}

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

  static const List<String> allKeys = [Keys.idKey, Keys.usernameKey,
    Keys.passwordKey, Keys.emailKey];

  Map<String, String> toMap() => {
    Keys.idKey: id.toString(),
    Keys.usernameKey: username,
    Keys.passwordKey: password,
    Keys.emailKey: email,
  };

  /// used for storing key value pairs in local storage
  static User? fromMap(Map<String, String> map) {
    if (map.containsKey(Keys.idKey) && map.containsKey(Keys.usernameKey)
      && map.containsKey(Keys.passwordKey) && map.containsKey(Keys.emailKey)) {
      final id = int.tryParse(map[Keys.idKey]!);
      if (id == null) {
        return null;
      }
      return User(
          id: id,
          username: map[Keys.usernameKey]!,
          password: map[Keys.passwordKey]!,
          email: map[Keys.emailKey]!
      );
    }
    return null;
  }

  User.fromJson(Map<String, dynamic> map)
    : id = map[Keys.idKey]!,
      username = map[Keys.usernameKey]!,
      password = map[Keys.passwordKey]!,
      email = map[Keys.emailKey]!;

  @override
  String toString() {
    return '''User(${Keys.idKey}: $id, ${Keys.usernameKey}: $username, ${Keys.passwordKey}: $password, ${Keys.emailKey}: $email)''';
  }
}

class NewUser extends Equatable {
  const NewUser({
    required this.username,
    required this.password,
    required this.email,
  }) : super();

  final String username;
  final String password;
  final String email;

  @override
  List<Object?> get props => [username, password, email];

  static const List<String> allKeys
  = [Keys.usernameKey, Keys.passwordKey, Keys.emailKey];

  Map<String, dynamic> toJson() => {
    Keys.usernameKey: username,
    Keys.passwordKey: password,
    Keys.emailKey: email,
  };

  @override
  String toString() {
    return '''NewUser(${Keys.usernameKey}: $username, ${Keys.passwordKey}: $password, ${Keys.emailKey}: $email)''';
  }
}