
import 'package:models/authentication_state.dart';
import 'package:models/user.dart';
import 'package:repositories/authentication_repository.dart';

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'authentication_event.dart';

const int apiDelay = 500;

class AuthenticationBloc extends Bloc<AuthenticationEvent, AuthenticationState> {
  AuthenticationBloc({
    required AuthenticationRepository authenticationRepository
  }) : _authenticationRepository = authenticationRepository,
        super(UnauthenticatedAuthenticationState());

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
      throw UnimplementedError("Unknwon AuthenticationEvent");
    }
  }

  Stream<AuthenticationState> _logoutStream(LogoutEvent event) async* {
    _authenticationRepository.deleteUser(); // TODO: extra state
    yield UnauthenticatedAuthenticationState();
  }

  Stream<AuthenticationState> _loginStream(LoginEvent event) async* {
    yield UnauthenticatedAuthenticationState(state: AsyncAuth.loginPending);
    // TODO: use api
    User user = await Future.delayed(
        const Duration(milliseconds: apiDelay), () => User(
        id: 1,
        username: event.username,
        password: event.password,
        email: "email@email.com",
    )
    );
    await _authenticationRepository.createUser(user);
    yield AuthenticatedAuthenticationState(user: user);
  }

  Stream<AuthenticationState> _registrationStream(RegisterEvent event) async* {
    yield UnauthenticatedAuthenticationState(
        state: AsyncAuth.registrationPending);
    // TODO: use api
    User user = await Future.delayed(
        const Duration(milliseconds: apiDelay), () => User(
        id: 1,
        username: event.username,
        password: event.password,
        email: event.email,
    )
    );
    await _authenticationRepository.createUser(user);
    yield AuthenticatedAuthenticationState(user: user);
  }
}
