import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:sport_log/data_provider/sync.dart';
import 'package:sport_log/models/user/user.dart';
import 'package:sport_log/settings.dart';

abstract class AuthenticationState extends Equatable {
  @override
  List<Object?> get props => [];
}

class Unauthenticated extends AuthenticationState {}

class Authenticated extends AuthenticationState {
  Authenticated({required this.user}) : super();

  final User user;

  @override
  List<Object?> get props => [user];
}

// TODO: do we really need this class?
class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  AuthenticationBloc()
      : super(Settings.instance.userExists()
            ? Authenticated(user: Settings.instance.user!)
            : Unauthenticated());

  @override
  Stream<AuthenticationState> mapEventToState(
    AuthenticationEvent event,
  ) async* {
    if (event is LogoutEvent) {
      yield* _logoutStream(event);
    } else if (event is LoginEvent) {
      yield* _loginStream(event);
    } else if (event is RegisterEvent) {
      yield* _registrationStream(event);
    } else {
      throw UnimplementedError("Unknown AuthenticationEvent");
    }
  }

  Stream<AuthenticationState> _logoutStream(LogoutEvent event) async* {
    Settings.instance.user = null;
    Sync.instance.stopSync();
    yield Unauthenticated();
  }

  Stream<AuthenticationState> _loginStream(LoginEvent event) async* {
    Settings.instance.user = event.user;
    Sync.instance.startSync();
    yield Authenticated(user: event.user);
  }

  Stream<AuthenticationState> _registrationStream(RegisterEvent event) async* {
    Settings.instance.user = event.user;
    Sync.instance.startSync();
    yield Authenticated(user: event.user);
  }
}

abstract class AuthenticationEvent extends Equatable {
  const AuthenticationEvent();

  @override
  List<Object?> get props => [];
}

class LoginEvent extends AuthenticationEvent {
  const LoginEvent({required this.user}) : super();

  final User user;

  @override
  List<Object?> get props => [user];
}

class LogoutEvent extends AuthenticationEvent {
  const LogoutEvent() : super();
}

class RegisterEvent extends AuthenticationEvent {
  const RegisterEvent({required this.user}) : super();

  final User user;

  @override
  List<Object?> get props => [user];
}
