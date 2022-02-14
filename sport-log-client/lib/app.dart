import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:provider/provider.dart';
import 'package:sport_log/data_provider/sync.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/theme.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/pages/map/map_page.dart';
import 'package:sport_log/pages/offline_maps/offline_maps_overview.dart';
import 'package:sport_log/pages/settings/settings_page.dart';
import 'package:sport_log/pages/timer/timer_page.dart';
import 'package:sport_log/pages/workout/cardio/cardio_details_page.dart';
import 'package:sport_log/pages/workout/cardio/cardio_edit_page.dart';
import 'package:sport_log/pages/workout/cardio/cardio_overview_page.dart';
import 'package:sport_log/pages/workout/cardio/route_overview_page.dart';
import 'package:sport_log/pages/workout/cardio/route_edit_page.dart';
import 'package:sport_log/pages/workout/cardio/tracking_page.dart';
import 'package:sport_log/pages/workout/cardio/tracking_settings_page.dart';
import 'package:sport_log/pages/landing/landing_page.dart';
import 'package:sport_log/pages/login/login_page.dart';
import 'package:sport_log/pages/workout/metcon_sessions/metcon_edit_page.dart';
import 'package:sport_log/pages/workout/metcon_sessions/metcon_overview_page.dart';
import 'package:sport_log/pages/movements/edit_page.dart';
import 'package:sport_log/pages/movements/overview_page.dart';
import 'package:sport_log/pages/login/registration_page.dart';
import 'package:sport_log/pages/workout/diary/diary_edit_page.dart';
import 'package:sport_log/pages/workout/diary/diary_overview_page.dart';
import 'package:sport_log/pages/workout/metcon_sessions/metcon_session_edit_page.dart';
import 'package:sport_log/pages/workout/metcon_sessions/metcon_session_overview_page.dart';
import 'package:sport_log/pages/workout/strength_sessions/strength_details_page.dart';
import 'package:sport_log/pages/workout/strength_sessions/strength_edit_page.dart';
import 'package:sport_log/pages/workout/strength_sessions/strength_overview_page.dart';
import 'package:sport_log/pages/workout/timeline/timeline_page.dart';
import 'package:sport_log/settings.dart';
//import 'package:sport_log/widgets/form_widgets/new_credentials_dialog.dart';

import 'pages/workout/metcon_sessions/metcon_session_details_page.dart';
import 'routes.dart';

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    //if (Provider.of<Sync>(context, listen: true).showNewCredentialsDialog) {
    //showNewCredentialsDialog(context: context);
    //}

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

    Defaults.mapbox.accessToken; // make sure access token is available

    Widget checkLogin(Widget Function(BuildContext) builder) {
      return Settings.userExists() ? builder(context) : const LandingPage();
    }

    Widget checkNotLogin(Widget Function(BuildContext) builder) {
      return Settings.userExists() ? const TimelinePage() : builder(context);
    }

    return KeyboardDismissOnTap(
      child: MaterialApp(
        routes: {
          Routes.landing: (_) => checkNotLogin((_) => const LandingPage()),
          Routes.login: (_) => checkNotLogin((_) => const LoginPage()),
          Routes.registration: (_) =>
              checkNotLogin((_) => const RegistrationPage()),
          Routes.timer: (_) => checkLogin((_) => const TimerPage()),
          Routes.map: (_) => checkLogin((_) => const MapPage()),
          Routes.offlineMaps: (_) => checkLogin((_) => const OfflineMapsPage()),
          Routes.settings: (_) => checkLogin((_) => const SettingsPage()),
          // movement
          Routes.movement.overview: (_) =>
              checkLogin((_) => const MovementsPage()),
          Routes.movement.edit: (_) => checkLogin((context) {
                final arg = ModalRoute.of(context)?.settings.arguments;
                if (arg is MovementDescription) {
                  return EditMovementPage(initialMovement: arg);
                } else if (arg is String) {
                  return EditMovementPage.fromName(initialName: arg);
                }
                return EditMovementPage.newMovement();
              }),
          // metcon
          Routes.metcon.overview: (_) => checkLogin((_) => const MetconsPage()),
          Routes.metcon.edit: (_) => checkLogin((context) {
                final arg = ModalRoute.of(context)?.settings.arguments;
                return EditMetconPage(
                  initialMetcon: (arg is MetconDescription) ? arg : null,
                );
              }),
          // timeline
          Routes.timeline.overview: (_) =>
              checkLogin((_) => const TimelinePage()),
          // metcon session
          Routes.metcon.sessionOverview: (_) =>
              checkLogin(((_) => const MetconSessionsPage())),
          Routes.metcon.sessionDetails: (context) => checkLogin((context) {
                final metconSessionDescription = ModalRoute.of(context)
                    ?.settings
                    .arguments as MetconSessionDescription;
                return MetconSessionDetailsPage(
                    metconSessionDescription: metconSessionDescription);
              }),
          Routes.metcon.sessionEdit: (context) => checkLogin((context) {
                final metconSessionDescription = ModalRoute.of(context)
                    ?.settings
                    .arguments as MetconSessionDescription?;
                return MetconSessionEditPage(
                    metconSessionDescription: metconSessionDescription);
              }),
          // strength
          Routes.strength.overview: (_) =>
              checkLogin((_) => const StrengthSessionsPage()),
          Routes.strength.details: (_) => checkLogin((context) {
                final arg = ModalRoute.of(context)?.settings.arguments;
                if (arg is! Int64) {
                  throw ArgumentError('StrengthSessionDetailsPage without id');
                }
                return StrengthSessionDetailsPage(id: arg);
              }),
          Routes.strength.edit: (_) => checkLogin((context) {
                final arg = ModalRoute.of(context)?.settings.arguments;
                if (arg is! StrengthSessionWithSets) {
                  throw ArgumentError(
                      'StrengthSessionEditPage without session');
                }
                return StrengthSessionEditPage(initialSession: arg);
              }),
          // cardio
          Routes.cardio.overview: (_) =>
              checkLogin((_) => const CardioSessionsPage()),
          Routes.cardio.trackingSettings: (_) =>
              checkLogin((_) => const CardioTrackingSettingsPage()),
          Routes.cardio.tracking: (context) => checkLogin((context) {
                final args =
                    ModalRoute.of(context)?.settings.arguments as List<dynamic>;
                return CardioTrackingPage(args[0] as Movement,
                    args[1] as CardioType, args[2] as Route?);
              }),
          Routes.cardio.cardioEdit: (context) => checkLogin((context) {
                final cardioSession = ModalRoute.of(context)?.settings.arguments
                    as CardioSession?;
                return CardioEditPage(
                  cardioSession: cardioSession,
                );
              }),
          Routes.cardio.cardioDetails: (context) => checkLogin((context) {
                final cardioSession =
                    ModalRoute.of(context)?.settings.arguments as CardioSession;
                return CardioDetailsPage(cardioSession: cardioSession);
              }),
          Routes.cardio.routeOverview: (_) =>
              checkLogin((_) => const RoutePage()),
          Routes.cardio.routeEdit: (context) => checkLogin((context) {
                final route =
                    ModalRoute.of(context)?.settings.arguments as Route?;
                return RouteEditPage(
                  route: route,
                );
              }),
          // diary
          Routes.diary.overview: (_) => checkLogin((_) => const DiaryPage()),
          Routes.diary.edit: (context) => checkLogin((context) {
                final diary =
                    ModalRoute.of(context)?.settings.arguments as Diary?;
                return DiaryEditPage(diary: diary);
              })
        },
        initialRoute:
            Settings.userExists() ? Routes.timeline.overview : Routes.landing,
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
