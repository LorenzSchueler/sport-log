
import 'package:equatable/equatable.dart';

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

  static const String usernameKey = "username";
  static const String passwordKey = "password";
  static const String emailKey = "email";

  static const List<String> allKeys = [usernameKey, passwordKey, emailKey];

  Map<String, dynamic> toJson() => {
    usernameKey: username,
    passwordKey: password,
    emailKey: email,
  };

  @override
  String toString() {
    return "NewUser($usernameKey: $username, $passwordKey: $password, $emailKey: $email)";
  }
}
