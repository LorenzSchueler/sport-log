import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sport_log/app.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/data_provider/data_providers/strength_data_provider.dart';
import 'package:sport_log/data_provider/sync.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/theme.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/pages/login/landing_page.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/test_data/movement_test_data.dart';
import 'package:sport_log/test_data/strength_test_data.dart';
import 'package:provider/provider.dart';

final _logger = Logger('MAIN');

Stream<double> initialize() async* {
  WidgetsFlutterBinding.ensureInitialized(); // TODO: necessary?
  yield 0.1;
  Defaults.mapbox.accessToken; // make sure access token is available
  yield 0.2;
  await Hive.initFlutter();
  yield 0.3;
  await Config.init();
  yield 0.4;
  await Settings.init();
  yield 0.5;
  await AppDatabase.init();
  yield 0.8;
  await Sync.instance.init();
  yield 0.9;
  if (Config.generateTestData) {
    insertTestData();
  }
  yield 1.0;
}

Future<void> insertTestData() async {
  final userId = Settings.userId;
  if (userId != null) {
    _logger.i('Generating test data ...');
    List<Movement> movements = [];
    if ((await AppDatabase.movements.getNonDeleted()).isEmpty) {
      movements = generateMovements(userId);
      await AppDatabase.movements
          .upsertMultiple(movements, synchronized: false);
    }
    final sessions = await generateStrengthSessions(userId);
    await StrengthSessionDescriptionDataProvider.instance
        .upsertMultipleSessions(sessions, synchronized: false);
    final sets = await generateStrengthSets();
    await StrengthSessionDescriptionDataProvider.instance
        .upsertMultipleSets(sets, synchronized: false);
    _logger.i(
      '''
        Generated
        ${movements.length} movements,
        ${sessions.length} strength sessions,
        ${sets.length} strength sets''',
    );
  }
}

Future<void> main() async {
  runApp(const InitAppWrapper());
}

class InitAppWrapper extends StatefulWidget {
  const InitAppWrapper({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => InitAppWrapperState();
}

class InitAppWrapperState extends State<InitAppWrapper> {
  double? _progress = 0.0;

  @override
  void initState() {
    _initialize();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _progress == null
        ? ChangeNotifierProvider.value(
            value: Sync.instance,
            child: const App(),
          )
        : MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: WelcomeScreen(
              content: Center(
                child: LinearProgressIndicator(value: _progress),
              ),
            ),
          );
  }

  Future<void> _initialize() async {
    await for (double progress in initialize()) {
      setState(() => _progress = progress);
    }
    setState(() => _progress = null);
  }
}
