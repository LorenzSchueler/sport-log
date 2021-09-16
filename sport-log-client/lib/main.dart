import 'package:fixnum/fixnum.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_log/app.dart';
import 'package:sport_log/blocs/authentication/authentication_bloc.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/data_provider/syncing.dart';
import 'package:sport_log/data_provider/user_state.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/helpers/bloc_observer.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/test_data/strength_test_data.dart';

final _logger = Logger('MAIN');

Future<void> initialize({bool doDownSync = true}) async {
  WidgetsFlutterBinding.ensureInitialized(); // TODO: necessary?
  await Config.init();
  await UserState.instance.init();
  if (UserState.instance.currentUser == null && Config.loggedInStart) {
    _logger.i('Logging in user1...');
    UserState.instance.setUser(User(
      id: Int64(1),
      username: 'user1',
      password: 'user1-passwd',
      email: 'email1',
    ));
  }
  await AppDatabase.instance?.init();
  await DownSync.instance.init().then((downSync) async {
    if (Config.doCleanStart) {
      _logger.i('Clean start on: deleting last sync datetime');
      await downSync.removeLastSync();
    }
    if (doDownSync) {
      downSync.sync().then((_) async {
        if (Config.generateTestData) {
          insertTestData();
        }
      });
    }
  });
  await UpSync.instance.init();
  Bloc.observer = SimpleBlocObserver();
}

Future<void> insertTestData() async {
  final userId = UserState.instance.currentUser?.id;
  if (userId != null) {
    _logger.i('Generating test data ...');
    final sessions = await generateStrengthSessions(userId);
    await AppDatabase.instance!.strengthSessions.upsertMultiple(sessions);
    final sets = await generateStrengthSets();
    await AppDatabase.instance!.strengthSets.upsertMultiple(sets);
    _logger.i(
        'Generated ${sessions.length} strength sessions, ${sets.length} strength sets');
  }
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
