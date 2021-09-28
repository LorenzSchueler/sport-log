import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/user_state.dart';
import 'package:sport_log/helpers/theme.dart';
import 'package:sport_log/models/metcon/metcon_description.dart';
import 'package:sport_log/models/movement/movement_description.dart';
import 'package:sport_log/models/strength/strength_session_description.dart';
import 'package:sport_log/pages/landing/landing_page.dart';
import 'package:sport_log/pages/login/login_page.dart';
import 'package:sport_log/pages/metcons/edit_page.dart';
import 'package:sport_log/pages/metcons/overview_page.dart';
import 'package:sport_log/pages/movements/edit_page.dart';
import 'package:sport_log/pages/movements/overview_page.dart';
import 'package:sport_log/pages/registration/registration_page.dart';
import 'package:sport_log/pages/workout/cardio_sessions/overview_page.dart';
import 'package:sport_log/pages/workout/strength_sessions/edit_page.dart';
import 'package:sport_log/pages/workout/workout_page.dart';
import 'package:sport_log/widgets/protected_route.dart';

import 'routes.dart';

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    // use themeDataFromColors to change theme data
    final darkTheme = themeDataFromColors(
      // for selected/clickable things
      primary: const Color(0xffa8d8ff),
      // only for small accents
      secondary: const Color(0xffba2f2f),
      brightness: Brightness.dark,
    );

    final lightTheme = themeDataFromColors(
      primary: const Color(0xff1f67a3), // for selected things
      secondary:
          const Color(0xffffa896), // for important things that you can click
      brightness: Brightness.light,
    );

    bool isAuthenticated = UserState.instance.currentUser != null;
    return MaterialApp(
      routes: {
        Routes.landing: (_) => const LandingPage(),
        Routes.login: (_) => const LoginPage(),
        Routes.registration: (_) => const RegistrationPage(),
        Routes.workout: (_) => ProtectedRoute(builder: (_) => WorkoutPage()),
        Routes.metcon.overview: (_) =>
            ProtectedRoute(builder: (_) => const MetconsPage()),
        Routes.metcon.edit: (_) => ProtectedRoute(builder: (context) {
              final arg = ModalRoute.of(context)?.settings.arguments;
              return EditMetconPage(
                initialMetcon: (arg is MetconDescription) ? arg : null,
              );
            }),
        Routes.movement.overview: (_) =>
            ProtectedRoute(builder: (_) => const MovementsPage()),
        Routes.movement.edit: (_) => ProtectedRoute(builder: (context) {
              final arg = ModalRoute.of(context)?.settings.arguments;
              if (arg is MovementDescription) {
                return EditMovementPage(initialMovement: arg);
              } else if (arg is String) {
                return EditMovementPage.fromName(initialName: arg);
              }
              return EditMovementPage.newMovement();
            }),
        Routes.editStrengthSession: (context) =>
            ProtectedRoute(builder: (context) {
              final dynamic arg = ModalRoute.of(context)?.settings.arguments;
              return EditStrengthSessionPage(
                  description: arg is StrengthSessionDescription ? arg : null);
            }),
        Routes.cardio.tracking: (_) => const CardioTrackingPage(),
      },
      initialRoute: isAuthenticated ? Routes.workout : Routes.landing,
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.dark,
      builder: (context, child) {
        if (child != null) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child,
          );
        } else {
          return Container();
        }
      },
    );
  }
}
