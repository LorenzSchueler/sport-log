import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sport_log/app.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/data_provider/sync.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/theme.dart';
import 'package:sport_log/pages/login/landing_page.dart';
import 'package:sport_log/settings.dart';
import 'package:provider/provider.dart';

Stream<double> initialize() async* {
  WidgetsFlutterBinding.ensureInitialized();
  if (Config.isTest) {
    dotenv.testLoad(fileInput: File("./.env").readAsStringSync());
  } else {
    await dotenv.load();
  }
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
  yield 0.7;
  await Sync.instance.init();
  yield 1.0;
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
  static final navigatorKey = GlobalKey<NavigatorState>();

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
            navigatorKey: navigatorKey,
            home: WelcomeScreen(
              content: Center(
                child: LinearProgressIndicator(value: _progress),
              ),
            ),
          );
  }

  Future<void> _initialize() async {
    await for (final double progress in initialize()) {
      setState(() => _progress = progress);
    }
    setState(() => _progress = null);
  }
}
