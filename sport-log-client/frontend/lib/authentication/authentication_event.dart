
part of 'authentication_bloc.dart';

abstract class AuthenticationEvent extends Equatable {
  const AuthenticationEvent();

  @override
  List<Object?> get props => [];
}

class LoginEvent extends AuthenticationEvent {
  const LoginEvent({
    required this.user
  }) : super();

  final User user;

  @override
  List<Object?> get props => [user];
}

class LogoutEvent extends AuthenticationEvent {
  const LogoutEvent() : super();
}

class RegisterEvent extends AuthenticationEvent {
  const RegisterEvent({
    required this.user
  }) : super();

  final User user;

  @override
  List<Object?> get props => [user];
}