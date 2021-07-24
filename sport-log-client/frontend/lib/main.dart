import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_log/repositories/authentication_repository.dart';
import 'package:sport_log/app.dart';
import 'package:flutter/widgets.dart';
import 'package:sport_log/authentication/authentication_bloc.dart';

void main() {
  final AuthenticationRepository authRepo = AuthenticationRepository();
  runApp(BlocProvider(
    create: (context) => AuthenticationBloc(
        authenticationRepository: authRepo,
    ),
    child: RepositoryProvider.value(
      value: authRepo,
      child: const App(),
    ),
  ));
}