import 'package:flutter/material.dart' hide Route;
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:sport_log/theme.dart';
import 'package:sport_log/main.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/settings.dart';

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => AppState();
}

class AppState extends State<App> {
  static final navigatorKey = GlobalKey<NavigatorState>();
  static BuildContext get globalContext =>
      navigatorKey.currentContext ??
      InitAppWrapperState.navigatorKey.currentContext!;

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissOnTap(
      child: MaterialApp(
        routes: Routes.all,
        initialRoute:
            Settings.userExists() ? Routes.timeline.overview : Routes.landing,
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        builder: ignoreSystemTextScaleFactor,
      ),
    );
  }
}

Widget ignoreSystemTextScaleFactor(BuildContext context, Widget? child) =>
    child != null
        ? MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: 1),
            child: child,
          )
        : Container();
