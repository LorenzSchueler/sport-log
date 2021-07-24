import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_log/repositories/authentication_repository.dart';
import 'package:sport_log/app.dart';
import 'package:flutter/widgets.dart';
import 'package:sport_log/authentication/authentication_bloc.dart';

import 'models/user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final AuthenticationRepository authRepo = AuthenticationRepository();
  User? user = await authRepo.getUser();
  final authBloc = AuthenticationBloc(
    authenticationRepository: authRepo,
    user: user
  );
  runApp(BlocProvider.value(
    value: authBloc,
    child: RepositoryProvider.value(
      value: authRepo,
      child: App(
        isAuthenticatedAtStart: user != null,
      ),
    ),
  ));
}