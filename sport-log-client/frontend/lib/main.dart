
import 'package:sport_log/api/api.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/helpers/bloc_observer.dart';
import 'package:sport_log/repositories/authentication_repository.dart';
import 'package:sport_log/repositories/movement_repository.dart';
import 'package:sport_log/repositories/metcon_repository.dart';
import 'package:sport_log/app.dart';
import 'package:sport_log/blocs/authentication/authentication_bloc.dart';
import 'package:sport_log/models/user.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  User? user;
  AuthenticationRepository? authRepo;
  if (!Config.isWeb) {
    authRepo = await AuthenticationRepository.getInstance();
    user = await authRepo.getUser();
  }
  final api = Api(urlBase: await Config.apiUrlBase);
  final authBloc = AuthenticationBloc(
      authenticationRepository: authRepo,
      api: api,
      user: user,
  );
  Bloc.observer = SimpleBlocObserver();
  runApp(BlocProvider.value(
    value: authBloc,
    child: MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepo),
        RepositoryProvider.value(value: api),
        RepositoryProvider.value(value: MovementRepository()),
        RepositoryProvider.value(value: MetconRepository()),
      ],
      child: App(
        isAuthenticatedAtStart: user != null,
      ),
    ),
  ));
}