
import 'package:sport_log/api/api.dart';
import 'package:sport_log/models/user/user.dart';
import 'package:sport_log/repositories/authentication_repository.dart';

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';

class AuthenticationBloc extends Bloc<AuthenticationEvent, AuthenticationState> {
  AuthenticationBloc({
    required AuthenticationRepository? authenticationRepository,
    required Api api,
    User? user,
  }) : _authenticationRepository = authenticationRepository,
       _api = api,
        super(user == null
          ? Unauthenticated()
          : Authenticated(user: user)) {
    if (user != null) {
      _api.setCurrentUser(user);
    }
  }

  final AuthenticationRepository? _authenticationRepository;
  final Api _api;

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
    _authenticationRepository?.deleteUser();
    _api.removeCurrentUser();
    yield Unauthenticated();
  }

  Stream<AuthenticationState> _loginStream(LoginEvent event) async* {
    _authenticationRepository?.createUser(event.user);
    yield Authenticated(user: event.user);
  }

  Stream<AuthenticationState> _registrationStream(RegisterEvent event) async* {
    _authenticationRepository?.createUser(event.user);
    yield Authenticated(user: event.user);
  }
}
