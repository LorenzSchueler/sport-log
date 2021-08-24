
import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/api/api_error.dart';
import 'package:sport_log/blocs/authentication/authentication_bloc.dart' as auth;
import 'package:sport_log/data_provider/syncing.dart';

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
    required Function(String) showErrorSnackBar,
  })
      : _authenticationBloc = authenticationBloc,
        _showErrorSnackBar = showErrorSnackBar,
        super(LoginState.idle);

  final auth.AuthenticationBloc _authenticationBloc;
  final Function(String) _showErrorSnackBar;

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
    final result = await (await Api.instance).getUser(event.username, event.password);
    if (result.isSuccess) {
      yield LoginState.successful;
      _authenticationBloc.add(auth.LoginEvent(user: result.success));
      (await DownSync.instance).sync();
    } else {
      _handleApiError(result.failure);
      yield LoginState.failed;
    }
  }

  void _handleApiError(ApiError error) {
    _showErrorSnackBar(error.toErrorMessage());
  }
}