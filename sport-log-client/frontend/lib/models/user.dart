
import 'package:equatable/equatable.dart';

class User extends Equatable {
  User({
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

  User.fromJson(Map<String, dynamic> json)
    : id = json[idKey],
      username = json[usernameKey],
      password = json[passwordKey],
      email = json[emailKey];

  Map<String, dynamic> toJson() => {
    idKey: id,
    usernameKey: username,
    passwordKey: password,
    emailKey: email,
  };
}