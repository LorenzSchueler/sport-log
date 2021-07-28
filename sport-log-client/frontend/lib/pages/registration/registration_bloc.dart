
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/models/new_user.dart';
import 'package:sport_log/blocs/authentication/authentication_bloc.dart' as auth;

enum RegistrationState {
  idle, pending, failed, successful
}

abstract class RegistrationEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SubmitRegistration extends RegistrationEvent {
  SubmitRegistration({
    required this.username,
    required this.email,
    required this.password,
  }) : super();
  
  final String username;
  final String email;
  final String password;

  @override
  List<Object?> get props => [username, email, password];

  NewUser toNewUser() => NewUser(
      username: username,
      password: password,
      email: email
  );
}

class RestartRegistration extends RegistrationEvent {}

class RegistrationBloc extends Bloc<RegistrationEvent, RegistrationState> {
  RegistrationBloc({
    required auth.AuthenticationBloc authenticationBloc,
    required Api api,
    required showErrorSnackBar,
  })
      : _authenticationBloc = authenticationBloc,
        _api = api,
        _showErrorSnackBar = showErrorSnackBar,
        super(RegistrationState.idle);

  final auth.AuthenticationBloc _authenticationBloc;
  final Api _api;
  final Function(String) _showErrorSnackBar;

  @override
  Stream<RegistrationState> mapEventToState(RegistrationEvent event) async* {
    if (event is RestartRegistration) {
      yield RegistrationState.idle;
    } else if (event is SubmitRegistration) {
      yield* _submitRegistration(event);
    }
  }

  Stream<RegistrationState> _submitRegistration(SubmitRegistration event) async* {
    yield RegistrationState.pending;
    try {
      final user = await _api.createUser(event.toNewUser());
      yield RegistrationState.successful;
      _authenticationBloc.add(auth.RegisterEvent(user: user));
    } on ApiError catch (e) {
      _handleApiError(e);
      yield RegistrationState.failed;
    } catch (e) {
      addError(e);
      yield RegistrationState.failed;
    }
  }

  void _handleApiError(ApiError error) {
    switch (error) {
      case ApiError.usernameTaken:
        _showErrorSnackBar("Username already taken. Use login instead.");
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