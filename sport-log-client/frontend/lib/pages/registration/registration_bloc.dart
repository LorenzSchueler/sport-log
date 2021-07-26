
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/models/new_user.dart';
import 'package:sport_log/models/user.dart';
import 'package:sport_log/authentication/authentication_bloc.dart' as auth;
import 'package:sport_log/repositories/authentication_repository.dart';

const int apiDelay = 500; // ms

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
    required AuthenticationRepository? authenticationRepository,
    required Api api,
  })
      : _authenticationBloc = authenticationBloc,
        _authenticationRepository = authenticationRepository,
        _api = api,
        super(RegistrationState.idle);

  final auth.AuthenticationBloc _authenticationBloc;
  final AuthenticationRepository? _authenticationRepository;
  final Api _api;

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
      await _authenticationRepository?.createUser(user);
      yield RegistrationState.successful;
      _authenticationBloc.add(auth.RegisterEvent(user: user));
    } on ApiError catch (e) {
      if (e != ApiError.usernameTaken) {
        addError(e);
      }
      yield RegistrationState.failed;
    } catch (e) {
      addError(e);
      yield RegistrationState.failed;
    }
  }
}