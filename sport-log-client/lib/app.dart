import 'package:flutter/material.dart' hide Route;
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sport_log/main.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  static final navigatorKey = GlobalKey<NavigatorState>();
  static BuildContext get globalContext =>
      navigatorKey.currentContext ??
      InitAppWrapperState.navigatorKey.currentContext!;

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissOnTap(
      child: Selector<Settings, bool>(
        // userId is set after the user has registered/ logged in/ chosen to use without account.
        selector: (_, settings) => settings.userId != null,
        builder: (context, userIdSet, _) => MaterialApp(
          routes: Routes.all,
          initialRoute: userIdSet ? Routes.timelineOverview : Routes.landing,
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale("en", "US"), Locale("en", "GB")],
          builder: ignoreSystemTextScaleFactor,
        ),
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
