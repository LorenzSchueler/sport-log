import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Settings;
import 'package:sport_log/app.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/data_provider/data_providers/metcon_data_provider.dart';
import 'package:sport_log/data_provider/data_providers/movement_data_provider.dart';
import 'package:sport_log/data_provider/sync.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/global_error_handler.dart';
import 'package:sport_log/helpers/map_download_utils.dart';
import 'package:sport_log/helpers/notification_controller.dart';
import 'package:sport_log/helpers/tts_utils.dart';
import 'package:sport_log/pages/login/welcome_screen.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/theme.dart';
import 'package:sport_log/widgets/dialogs/new_credentials_dialog.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// ignore: long-method
Stream<double> initialize() async* {
  WidgetsFlutterBinding.ensureInitialized();
  if (!Config.isWeb) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }
  yield 0.1;
  await Config.init(); // throws InitException error
  yield 0.2;
  await Hive.initFlutter();
  yield 0.4;
  await Settings.instance.init(override: Config.isTest);
  yield 0.5;
  await NotificationController.init();
  yield 0.6;
  MapboxOptions.setAccessToken(Config.instance.accessToken);
  await MapDownloadUtils.globalInit();
  await TtsUtils.init();
  yield 0.7;
  if (Config.isWindows || Config.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  await AppDatabase.init();
  await MovementDataProvider().setDefaultMovement();
  await MetconDescriptionDataProvider().setDefaultMetconDescription();
  yield 0.9;
  await Sync.instance.init();
  yield 1.0;
}

void main() {
  GlobalErrorHandler.run(() => runApp(const InitAppWrapper()));
}

class InitAppWrapper extends StatefulWidget {
  const InitAppWrapper({super.key});

  @override
  State<StatefulWidget> createState() => InitAppWrapperState();
}

class InitAppWrapperState extends State<InitAppWrapper> {
  static final navigatorKey = GlobalKey<NavigatorState>();

  double? _progress = 0;

  Object? _error;

  @override
  void initState() {
    super.initState();
    initialize().listen(
      (progress) => setState(() => _progress = progress),
      onDone: () {
        NewCredentialsDialog.isShown = false;
        setState(() => _progress = null);
      },
      onError: (Object error) => setState(() => _error = error),
      cancelOnError: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _progress == null
        ? const App()
        : MaterialApp(
            debugShowCheckedModeBanner: false,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            navigatorKey: navigatorKey,
            home: WelcomeScreen(
              content: Column(
                children: [
                  LinearProgressIndicator(value: _progress),
                  if (_error != null) ...[
                    Defaults.sizedBox.vertical.normal,
                    Text(
                      _error.toString(),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.red),
                    ),
                  ],
                ],
              ),
            ),
            builder: ignoreSystemTextScaleFactor,
          );
  }
}
