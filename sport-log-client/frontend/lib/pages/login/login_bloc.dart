
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_log/models/user.dart';
import 'package:sport_log/authentication/authentication_bloc.dart' as auth;
import 'package:sport_log/repositories/authentication_repository.dart';

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
  LoginBloc({
    required auth.AuthenticationBloc authenticationBloc,
    required AuthenticationRepository authenticationRepository,
  })
      : _authenticationBloc = authenticationBloc,
        _authenticationRepository = authenticationRepository,
        super(LoginState.idle);

  final auth.AuthenticationBloc _authenticationBloc;
  final AuthenticationRepository _authenticationRepository;

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
    await _authenticationRepository.createUser(user);
    yield LoginState.successful;
    _authenticationBloc.add(auth.LoginEvent(user: user));
  }
}