import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:sport_log/data_provider/user_state.dart';
import 'package:sport_log/helpers/theme.dart';
import 'package:sport_log/models/cardio/cardio_session.dart';
import 'package:sport_log/models/cardio/route.dart';
import 'package:sport_log/models/metcon/metcon_description.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/movement/movement_description.dart';
import 'package:sport_log/models/strength/strength_session_with_sets.dart';
import 'package:sport_log/pages/workout/cardio/route_planing_page.dart';
import 'package:sport_log/pages/workout/cardio/tracking_page.dart';
import 'package:sport_log/pages/workout/cardio/tracking_settings_page.dart';
import 'package:sport_log/pages/landing/landing_page.dart';
import 'package:sport_log/pages/login/login_page.dart';
import 'package:sport_log/pages/metcons/edit_page.dart';
import 'package:sport_log/pages/metcons/overview_page.dart';
import 'package:sport_log/pages/movements/edit_page.dart';
import 'package:sport_log/pages/movements/overview_page.dart';
import 'package:sport_log/pages/registration/registration_page.dart';
import 'package:sport_log/pages/workout/diary/diary_edit_page.dart';
import 'package:sport_log/pages/workout/strength_sessions/details_page.dart';
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
    return KeyboardDismissOnTap(
      child: MaterialApp(
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
          Routes.strength.details: (_) => ProtectedRoute(builder: (context) {
                final arg = ModalRoute.of(context)?.settings.arguments;
                if (arg is! Int64) {
                  throw ArgumentError('StrengthSessionDetailsPage without id');
                }
                return StrengthSessionDetailsPage(id: arg);
              }),
          Routes.strength.edit: (_) => ProtectedRoute(builder: (context) {
                final arg = ModalRoute.of(context)?.settings.arguments;
                if (arg is! StrengthSessionWithSets) {
                  throw ArgumentError(
                      'StrengthSessionEditPage without session');
                }
                return StrengthSessionEditPage(initialSession: arg);
              }),
          Routes.cardio.tracking_settings: (_) =>
              const CardioTrackingSettingsPage(),
          Routes.cardio.tracking: (context) {
            final List<dynamic> args =
                ModalRoute.of(context)?.settings.arguments as List<dynamic>;
            return CardioTrackingPage(
                args[0] as Movement, args[1] as CardioType, args[2] as Route?);
          },
          Routes.cardio.route_planning: (_) => const RoutePlanningPage(),
          Routes.diary.edit: (_) => const DiaryEditPage(),
        },
        initialRoute: isAuthenticated ? Routes.workout : Routes.landing,
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.dark,
        builder: (context, child) {
          if (child != null) {
            return MediaQuery(
              data:
                  MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
              child: child,
            );
          } else {
            return Container();
          }
        },
      ),
    );
  }
}
