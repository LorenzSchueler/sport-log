
import 'package:equatable/equatable.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/api/api_error.dart';
import 'package:sport_log/blocs/authentication/authentication_bloc.dart' as auth;
import 'package:sport_log/models/user/user.dart';

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
}

class RestartRegistration extends RegistrationEvent {}

class RegistrationBloc extends Bloc<RegistrationEvent, RegistrationState> {
  RegistrationBloc({
    required auth.AuthenticationBloc authenticationBloc,
    required showErrorSnackBar,
  })
      : _authenticationBloc = authenticationBloc,
        _api = Api.instance,
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
      final user = User(
        id: Int64(1), // TODO: random number
        email: event.email,
        username: event.username,
        password: event.password,
      );
      await _api.createUser(user);
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
    _showErrorSnackBar(error.toErrorMessage());
  }
}