import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:sport_log/data_provider/user_state.dart';
import 'package:sport_log/helpers/theme.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/models/cardio/cardio_session.dart';
import 'package:sport_log/models/cardio/route.dart';
import 'package:sport_log/models/metcon/metcon_description.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/movement/movement_description.dart';
import 'package:sport_log/models/strength/strength_session_with_sets.dart';
import 'package:sport_log/pages/workout/cardio/cardio_details_page.dart';
import 'package:sport_log/pages/workout/cardio/cardio_edit_page.dart';
import 'package:sport_log/pages/workout/cardio/overview_page.dart';
import 'package:sport_log/pages/workout/cardio/route_overview_page.dart';
import 'package:sport_log/pages/workout/cardio/route_edit_page.dart';
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
import 'package:sport_log/pages/workout/diary/overview_page.dart';
import 'package:sport_log/pages/workout/metcon_sessions/overview_page.dart';
import 'package:sport_log/pages/workout/strength_sessions/details_page.dart';
import 'package:sport_log/pages/workout/strength_sessions/edit_page.dart';
import 'package:sport_log/pages/workout/strength_sessions/overview_page.dart';
import 'package:sport_log/pages/workout/timeline/overview_page.dart';
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
          // movement
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
          // metcon
          Routes.metcon.overview: (_) =>
              ProtectedRoute(builder: (_) => const MetconsPage()),
          // timeline
          Routes.timeline.overview: (_) =>
              ProtectedRoute(builder: (_) => const TimelinePage()),
          // metcon session
          Routes.metcon.sessionOverview: (_) =>
              ProtectedRoute(builder: (_) => const MetconSessionsPage()),
          Routes.metcon.edit: (_) => ProtectedRoute(builder: (context) {
                final arg = ModalRoute.of(context)?.settings.arguments;
                return EditMetconPage(
                  initialMetcon: (arg is MetconDescription) ? arg : null,
                );
              }),
          // strength
          Routes.strength.overview: (_) =>
              ProtectedRoute(builder: (_) => const StrengthSessionsPage()),
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
          // cardio
          Routes.cardio.overview: (_) =>
              ProtectedRoute(builder: (_) => const CardioSessionsPage()),
          Routes.cardio.trackingSettings: (_) =>
              const CardioTrackingSettingsPage(),
          Routes.cardio.tracking: (context) {
            final List<dynamic> args =
                ModalRoute.of(context)?.settings.arguments as List<dynamic>;
            return CardioTrackingPage(
                args[0] as Movement, args[1] as CardioType, args[2] as Route?);
          },
          Routes.cardio.cardioEdit: (context) {
            final CardioSession? cardioSession =
                ModalRoute.of(context)?.settings.arguments as CardioSession?;
            return CardioEditPage(
              cardioSession: cardioSession,
            );
          },
          Routes.cardio.cardioDetails: (context) {
            final cardioSession =
                ModalRoute.of(context)?.settings.arguments as CardioSession;
            return CardioDetailsPage(cardioSession: cardioSession);
          },
          Routes.cardio.routeOverview: (_) {
            return const RoutePage();
          },
          Routes.cardio.routeEdit: (context) {
            final Route? route =
                ModalRoute.of(context)?.settings.arguments as Route?;
            return RouteEditPage(
              route: route,
            );
          },
          // diary
          Routes.diary.overview: (_) =>
              ProtectedRoute(builder: (_) => const DiaryPage()),
          Routes.diary.edit: (_) => const DiaryEditPage(),
        },
        initialRoute:
            isAuthenticated ? Routes.timeline.overview : Routes.landing,
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
