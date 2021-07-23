import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repositories/authentication_repository.dart';
import 'package:sport_log/app.dart';
import 'package:flutter/widgets.dart';
import 'package:sport_log/authentication/authentication_bloc.dart';

void main() {
  runApp(BlocProvider(
    create: (context) => AuthenticationBloc(
        authenticationRepository: AuthenticationRepository()
    ),
    child: const App(),
  ));
}