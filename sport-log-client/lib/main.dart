import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_log/app.dart';
import 'package:sport_log/blocs/authentication/authentication_bloc.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/data_provider/syncing.dart';
import 'package:sport_log/data_provider/user_state.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/helpers/bloc_observer.dart';

Future<void> initialize({bool doDownSync = true}) async {
  WidgetsFlutterBinding.ensureInitialized(); // TODO: necessary?
  await Config.init();
  await UserState.instance.init();
  await AppDatabase.instance?.init().then((_) {
    DownSync.instance.init().then((downSync) {
      if (doDownSync) downSync.sync();
    });
  });
  await UpSync.instance.init();
  Bloc.observer = SimpleBlocObserver();
  (await AppDatabase.instance!.movements.getNonDeleted()).result((movements) {
    print(movements);
  }, (error) {});
}

void main() async {
  initialize().then((_) {
    runApp(MultiBlocProvider(
      providers: [
        BlocProvider.value(value: AuthenticationBloc()),
      ],
      child: const App(),
    ));
  });
}
