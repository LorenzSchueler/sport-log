import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:sport_log/data_provider/sync.dart';
import 'package:sport_log/data_provider/user_state.dart';
import 'package:sport_log/models/user/user.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';

// TODO: do we really need this class?
class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  AuthenticationBloc()
      : super(UserState.instance.currentUser == null
            ? Unauthenticated()
            : Authenticated(user: UserState.instance.currentUser!));

  final UserState _userState = UserState.instance;

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
    _userState.deleteUser();
    Sync.instance.logout();
    yield Unauthenticated();
  }

  Stream<AuthenticationState> _loginStream(LoginEvent event) async* {
    _userState.setUser(event.user);
    Sync.instance.login();
    yield Authenticated(user: event.user);
  }

  Stream<AuthenticationState> _registrationStream(RegisterEvent event) async* {
    _userState.setUser(event.user);
    Sync.instance.login();
    yield Authenticated(user: event.user);
  }
}
