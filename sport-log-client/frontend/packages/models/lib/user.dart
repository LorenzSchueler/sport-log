
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
}