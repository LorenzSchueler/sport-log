
part of 'authentication_bloc.dart';

abstract class AuthenticationEvent extends Equatable {
  const AuthenticationEvent();

  @override
  List<Object> get props => [];
}

class LoginEvent extends AuthenticationEvent {
  const LoginEvent({
    required this.username,
    required this.password,
  }) : super();

  final String username;
  final String password;

  @override
  List<Object> get props => [username, password];
}

class LogoutEvent extends AuthenticationEvent {
  const LogoutEvent() : super();
}

class RegisterEvent extends AuthenticationEvent {
  const RegisterEvent({
    required this.username,
    required this.password,
    required this.email
  }) : super();

  final String username;
  final String password;
  final String email;
}