
import 'package:equatable/equatable.dart';

import 'keys.dart';

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
