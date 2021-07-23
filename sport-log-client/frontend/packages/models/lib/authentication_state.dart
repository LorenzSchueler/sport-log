import 'package:equatable/equatable.dart';

import 'user.dart';

enum AsyncAuth {
  idle, loginPending, loginFailed, registrationPending, registrationFailed
}

abstract class AuthenticationState {}

class UnauthenticatedAuthenticationState extends AuthenticationState {
  AsyncAuth state;

  UnauthenticatedAuthenticationState({this.state = AsyncAuth.idle})
      : super();

  bool operator ==(o) => o is UnauthenticatedAuthenticationState
      && o.state == state;
}

class AuthenticatedAuthenticationState extends AuthenticationState {
  AuthenticatedAuthenticationState({
    required this.user
  }) : super();

  final User user;

  @override
  bool operator ==(o) => o is AuthenticatedAuthenticationState
      && o.user == user;
}