import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sport_log/app.dart';
import 'package:sport_log/blocs/authentication/authentication_bloc.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/data_provider/data_providers/strength_data_provider.dart';
import 'package:sport_log/data_provider/sync.dart';
import 'package:sport_log/data_provider/user_state.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/helpers/bloc_observer.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/test_data/movement_test_data.dart';
import 'package:sport_log/test_data/strength_test_data.dart';
import 'package:provider/provider.dart';

import 'models/movement/movement.dart';

final _logger = Logger('MAIN');

Future<void> initialize({bool doDownSync = true}) async {
  WidgetsFlutterBinding.ensureInitialized(); // TODO: necessary?
  await Hive.initFlutter();
  await Config.init();
  await UserState.instance.init();
  await AppDatabase.instance?.init();
  await Sync.instance.init();
  if (Config.generateTestData) {
    insertTestData();
  }
  Bloc.observer = SimpleBlocObserver();
}

Future<void> insertTestData() async {
  final userId = UserState.instance.currentUser?.id;
  if (userId != null) {
    _logger.i('Generating test data ...');
    List<Movement> movements = [];
    if ((await AppDatabase.instance!.movements.getNonDeleted()).isEmpty) {
      movements = generateMovements(userId);
      await AppDatabase.instance!.movements
          .upsertMultiple(movements, synchronized: false);
    }
    final sessions = await generateStrengthSessions(userId);
    await StrengthDataProvider.instance
        .upsertMultipleSessions(sessions, synchronized: false);
    final sets = await generateStrengthSets();
    await StrengthDataProvider.instance
        .upsertMultipleSets(sets, synchronized: false);
    _logger.i('''
        Generated
        ${movements.length} movements,
        ${sessions.length} strength sessions,
        ${sets.length} strength sets''');
  }
}

void main() async {
  initialize().then((_) {
    runApp(MultiBlocProvider(
      providers: [
        BlocProvider.value(value: AuthenticationBloc()),
      ],
      child: ChangeNotifierProvider.value(
        value: Sync.instance,
        child: const App(),
      ),
    ));
  });
}
