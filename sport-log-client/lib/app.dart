import 'package:flutter/material.dart' hide Route;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sport_log/data_provider/sync.dart';
import 'package:sport_log/main.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  static final navigatorKey = GlobalKey<NavigatorState>();
  static BuildContext? get globalContextOptional =>
      navigatorKey.currentContext ??
      InitAppWrapperState.navigatorKey.currentContext;
  static BuildContext get globalContext => globalContextOptional!;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<Sync>.value(value: Sync.instance),
          ChangeNotifierProvider<Settings>.value(value: Settings.instance),
        ],
        child: MaterialApp(
          routes: Routes.all,
          initialRoute:
              Settings.instance.userId != null // changes ignored on purpose
                  ? Routes.timelineOverview
                  : Routes.landing,
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
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.noScaling),
            child: child,
          )
        : Container();
