
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
}

class RestartRegistration extends RegistrationEvent {}

class RegistrationBloc extends Bloc<RegistrationEvent, RegistrationState> {
  RegistrationBloc({
    required auth.AuthenticationBloc authenticationBloc,
    required AuthenticationRepository? authenticationRepository,
  })
      : _authenticationBloc = authenticationBloc,
        _authenticationRepository = authenticationRepository,
        super(RegistrationState.idle);

  final auth.AuthenticationBloc _authenticationBloc;
  final AuthenticationRepository? _authenticationRepository;

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
    await Future.delayed(const Duration(milliseconds: apiDelay));
    if (event.username == "nonexistent") {
      yield RegistrationState.failed;
    } else {
      final user = User(
          id: 1,
          username: event.username,
          password: event.password,
          email: event.email,
      );
      await _authenticationRepository?.createUser(user);
      yield RegistrationState.successful;
      _authenticationBloc.add(auth.RegisterEvent(user: user));
    }
  }
}