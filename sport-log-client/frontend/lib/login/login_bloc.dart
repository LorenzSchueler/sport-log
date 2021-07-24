
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:models/authentication_state.dart';
import 'package:models/user.dart';
import 'package:sport_log/authentication/authentication_bloc.dart';

const int apiDelay = 500; // ms

enum LoginState {
  idle, pending, failed, successful
}

abstract class LoginEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SubmitLogin extends LoginEvent {
  SubmitLogin({
    required this.username,
    required this.password,
  }) : super();

  final String username;
  final String password;

  @override
  List<Object?> get props => [username, password];
}

class RestartLogin extends LoginEvent {}

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc(AuthenticationBloc bloc)
      : _authenticationBloc = bloc,
        super(LoginState.idle);

  final AuthenticationBloc _authenticationBloc;

  @override
  Stream<LoginState> mapEventToState(LoginEvent event) async* {
    if (event is RestartLogin) {
      yield LoginState.idle;
    } else if (event is SubmitLogin) {
      yield* _submitLogin(event);
    }
  }

  Stream<LoginState> _submitLogin(SubmitLogin event) async* {
    yield LoginState.pending;
    User user = await Future.delayed(
      const Duration(milliseconds: apiDelay),
        () => User(
            id: 1,
            username: event.username,
            password: event.password,
            email: "email@domain.com"
        )
    );
    yield LoginState.successful;
    _authenticationBloc.add(AuthenticatedEvent(user: user));
  }
}