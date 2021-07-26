
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/authentication/authentication_bloc.dart' as auth;
import 'package:sport_log/repositories/authentication_repository.dart';

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
    required AuthenticationRepository? authenticationRepository,
    required Api api,
    required Function(String) showErrorSnackBar,
  })
      : _authenticationBloc = authenticationBloc,
        _authenticationRepository = authenticationRepository,
        _api = api,
        _showErrorSnackBar = showErrorSnackBar,
        super(LoginState.idle);

  final auth.AuthenticationBloc _authenticationBloc;
  final AuthenticationRepository? _authenticationRepository;
  final Api _api;
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
    try {
      final user = await _api.getUser(event.username, event.password);
      await _authenticationRepository?.createUser(user);
      yield LoginState.successful;
      _authenticationBloc.add(auth.LoginEvent(user: user));
    } on ApiError catch (e) {
      _handleApiError(e);
      yield LoginState.failed;
    } catch (e) {
      addError(e);
      yield LoginState.failed;
    }
  }

  void _handleApiError(ApiError error) {
    switch (error) {
      case ApiError.loginFailed:
        _showErrorSnackBar("Wrong credentials.");
        break;
      case ApiError.unknown:
        _showErrorSnackBar("An unknown api error occurred.");
        break;
      case ApiError.noInternetConnection:
        _showErrorSnackBar("No internet connection.");
        break;
      default:
        _showErrorSnackBar("An unhandled error occurred.");
    }
  }
}