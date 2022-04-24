import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sport_log/app.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/data_provider/sync.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/theme.dart';
import 'package:sport_log/pages/login/landing_page.dart';
import 'package:sport_log/settings.dart';
import 'package:provider/provider.dart';
import 'package:sport_log/widgets/dialogs/new_credentials_dialog.dart';

Stream<double> initialize() async* {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  yield 0.1;
  await Config.init();
  yield 0.2;
  await Hive.initFlutter();
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
            builder: ignoreSystemTextScaleFactor,
          );
  }

  Future<void> _initialize() async {
    await for (final double progress in initialize()) {
      setState(() => _progress = progress);
    }
    NewCredentialsDialog.isShown = false;
    setState(() => _progress = null);
  }
}
