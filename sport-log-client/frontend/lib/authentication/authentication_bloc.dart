
import 'package:sport_log/models/user.dart';
import 'package:sport_log/repositories/authentication_repository.dart';

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';

const int apiDelay = 500;

class AuthenticationBloc extends Bloc<AuthenticationEvent, AuthenticationState> {
  AuthenticationBloc({
    required AuthenticationRepository authenticationRepository,
    User? user,
  }) : _authenticationRepository = authenticationRepository,
        super(user == null
          ? Unauthenticated()
          : Authenticated(user: user));

  final AuthenticationRepository _authenticationRepository;

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
    _authenticationRepository.deleteUser(); // TODO: this should be in another bloc
    yield Unauthenticated();
  }

  Stream<AuthenticationState> _loginStream(LoginEvent event) async* {
    yield Authenticated(user: event.user);
  }

  Stream<AuthenticationState> _registrationStream(RegisterEvent event) async* {
    await _authenticationRepository.createUser(event.user);
    yield Authenticated(user: event.user);
  }
}
