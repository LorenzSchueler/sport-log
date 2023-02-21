import 'package:flutter/material.dart' hide Route;
import 'package:sport_log/config.dart';
import 'package:sport_log/helpers/heart_rate_utils.dart';
import 'package:sport_log/models/action/action_provider_description.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/models/cardio/cardio_session_description.dart';
import 'package:sport_log/pages/action/action_event_edit_page.dart';
import 'package:sport_log/pages/action/action_provider_overview_page.dart';
import 'package:sport_log/pages/action/action_rule_edit_page.dart';
import 'package:sport_log/pages/action/platform_overview_page.dart';
import 'package:sport_log/pages/heart_rate/heart_rate_page.dart';
import 'package:sport_log/pages/login/landing_page.dart';
import 'package:sport_log/pages/login/login_page.dart';
import 'package:sport_log/pages/map/map_page.dart';
import 'package:sport_log/pages/movements/movement_edit_page.dart';
import 'package:sport_log/pages/movements/movement_overview_page.dart';
import 'package:sport_log/pages/offline_maps/offline_maps_overview.dart';
import 'package:sport_log/pages/platform_not_supported_page.dart';
import 'package:sport_log/pages/settings/about_page.dart';
import 'package:sport_log/pages/settings/settings_page.dart';
import 'package:sport_log/pages/timer/timer_page.dart';
import 'package:sport_log/pages/workout/cardio/cardio_details_page.dart';
import 'package:sport_log/pages/workout/cardio/cardio_edit_page.dart';
import 'package:sport_log/pages/workout/cardio/cardio_overview_page.dart';
import 'package:sport_log/pages/workout/cardio/route_details_page.dart';
import 'package:sport_log/pages/workout/cardio/route_edit_page.dart';
import 'package:sport_log/pages/workout/cardio/route_overview_page.dart';
import 'package:sport_log/pages/workout/cardio/route_upload_page.dart';
import 'package:sport_log/pages/workout/cardio/tracking_page.dart';
import 'package:sport_log/pages/workout/cardio/tracking_settings_page.dart';
import 'package:sport_log/pages/workout/diary/diary_edit_page.dart';
import 'package:sport_log/pages/workout/diary/diary_overview_page.dart';
import 'package:sport_log/pages/workout/metcon_sessions/metcon_details_page.dart';
import 'package:sport_log/pages/workout/metcon_sessions/metcon_edit_page.dart';
import 'package:sport_log/pages/workout/metcon_sessions/metcon_overview_page.dart';
import 'package:sport_log/pages/workout/metcon_sessions/metcon_session_details_page.dart';
import 'package:sport_log/pages/workout/metcon_sessions/metcon_session_edit_page.dart';
import 'package:sport_log/pages/workout/metcon_sessions/metcon_session_overview_page.dart';
import 'package:sport_log/pages/workout/strength_sessions/strength_details_page.dart';
import 'package:sport_log/pages/workout/strength_sessions/strength_edit_page.dart';
import 'package:sport_log/pages/workout/strength_sessions/strength_overview_page.dart';
import 'package:sport_log/pages/workout/timeline/timeline_page.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/dialogs/message_dialog.dart';

abstract class Routes {
  static const landing = '/landing';
  static const login = '/login';
  static const registration = '/register';
  static const noAccount = '/no_account';
  static const timer = "/timer";
  static const map = "/map";
  static const offlineMaps = "/offline_maps";
  static const heartRate = "/heart_rate";
  static const settings = "/settings";
  static const about = "/about";
  // platform & ap
  static const String platformOverview = '/action/platform_overview';
  static const String actionProviderOverview = '/action/action_overview';
  static const String actionRuleEdit = '/action/action_rule_edit';
  static const String actionEventEdit = '/action/action_event_edit';
  // movement
  static const String movementOverview = '/movement/overview';
  static const String movementEdit = '/movement/edit';
  // timeline
  static const String timelineOverview = '/timeline/overview';
  // strength
  static const String strengthOverview = '/strength/overview';
  static const String strengthDetails = '/strength/details';
  static const String strengthEdit = '/strength/edit';
  // metcon
  static const String metconOverview = '/metcon/overview';
  static const String metconDetails = '/metcon/details';
  static const String metconEdit = '/metcon/edit';
  // metcon session
  static const String metconSessionOverview = '/metcon_session/overview';
  static const String metconSessionDetails = '/metcon_session/details';
  static const String metconSessionEdit = '/metcon_session/edit';
  // route
  static const String routeOverview = '/route/overview';
  static const String routeDetails = '/route/details';
  static const String routeEdit = '/route/edit';
  static const String routeUpload = '/route/upload';
  // cardio
  static const String cardioOverview = '/cardio/overview';
  static const String cardioDetails = '/cardio/details';
  static const String cardioEdit = '/cardio/edit';
  static const String trackingSettings = '/cardio/tracking_settings';
  static const String tracking = '/cardio/tracking';
  // diary
  static const String diaryOverview = '/diary/overview';
  static const String diaryEdit = '/diary/edit';

  static Widget _checkLogin(Widget Function() builder) {
    return Settings.instance.userExists() ? builder() : const LandingPage();
  }

  static Widget _checkLoginAndroidIos(
    BuildContext context,
    Widget Function() builder,
  ) {
    return Settings.instance.userExists()
        ? Config.isAndroid || Config.isIOS
            ? builder()
            : ModalRoute.of(context)!.isFirst
                ? const PlatformNotSupportedPage()
                : const MessageDialog(
                    text: "The selected page is not supported on you platform.",
                    title: null,
                  )
        : const LandingPage();
  }

  static Widget _checkNotLogin(Widget Function() builder) {
    return Settings.instance.userExists() ? TimelinePage() : builder();
  }

  static final Map<String, Widget Function(BuildContext)> _routeList = {
    Routes.landing: (_) => _checkNotLogin(() => const LandingPage()),
    Routes.login: (_) =>
        _checkNotLogin(() => const LoginPage(loginType: LoginType.login)),
    Routes.registration: (_) =>
        _checkNotLogin(() => const LoginPage(loginType: LoginType.register)),
    Routes.noAccount: (_) =>
        _checkNotLogin(() => const LoginPage(loginType: LoginType.noAccount)),
    Routes.timer: (_) => _checkLogin(() => const TimerPage()),
    Routes.map: (context) =>
        _checkLoginAndroidIos(context, () => const MapPage()),
    Routes.offlineMaps: (context) =>
        _checkLoginAndroidIos(context, () => const OfflineMapsPage()),
    Routes.heartRate: (context) =>
        _checkLoginAndroidIos(context, () => const HeartRatePage()),
    Routes.settings: (_) => _checkLogin(() => const SettingsPage()),
    Routes.about: (_) => _checkLogin(() => const AboutPage()),
    // platform & ap
    Routes.platformOverview: (_) =>
        _checkLogin(() => const PlatformOverviewPage()),
    Routes.actionProviderOverview: (context) => _checkLogin(() {
          final actionProvider =
              ModalRoute.of(context)!.settings.arguments! as ActionProvider;
          return ActionProviderOverviewPage(actionProvider: actionProvider);
        }),
    Routes.actionRuleEdit: (context) => _checkLogin(() {
          final args =
              ModalRoute.of(context)!.settings.arguments! as List<dynamic>;
          return ActionRuleEditPage(
            actionProviderDescription: args[0] as ActionProviderDescription,
            actionRule: args[1] as ActionRule?,
          );
        }),
    Routes.actionEventEdit: (context) => _checkLogin(() {
          final args =
              ModalRoute.of(context)!.settings.arguments! as List<dynamic>;
          return ActionEventEditPage(
            actionProviderDescription: args[0] as ActionProviderDescription,
            actionEvent: args[1] as ActionEvent?,
          );
        }),
    // movement
    Routes.movementOverview: (_) => _checkLogin(MovementsPage.new),
    Routes.movementEdit: (context) => _checkLogin(() {
          final arg = ModalRoute.of(context)?.settings.arguments;
          if (arg is MovementDescription) {
            return MovementEditPage(movementDescription: arg);
          } else if (arg is String) {
            return MovementEditPage.fromName(name: arg);
          }
          return const MovementEditPage(movementDescription: null);
        }),
    // timeline
    Routes.timelineOverview: (_) => _checkLogin(TimelinePage.new),
    // strength
    Routes.strengthOverview: (_) => _checkLogin(StrengthSessionsPage.new),
    Routes.strengthDetails: (context) => _checkLogin(() {
          final strengthSessionDescription = ModalRoute.of(context)!
              .settings
              .arguments! as StrengthSessionDescription;
          return StrengthSessionDetailsPage(
            strengthSessionDescription: strengthSessionDescription,
          );
        }),
    Routes.strengthEdit: (context) => _checkLogin(() {
          var isNew = false;
          var arg = ModalRoute.of(context)?.settings.arguments
              as StrengthSessionDescription?;
          if (arg == null) {
            arg = StrengthSessionDescription.defaultValue();
            isNew = true;
          }
          return arg == null
              ? const MovementEditPage(movementDescription: null)
              : StrengthSessionEditPage(
                  strengthSessionDescription: arg,
                  isNew: isNew,
                );
        }),
    // metcon
    Routes.metconOverview: (_) => _checkLogin(MetconsPage.new),
    Routes.metconDetails: (context) => _checkLogin(() {
          final metconDescription =
              ModalRoute.of(context)!.settings.arguments! as MetconDescription;
          return MetconDetailsPage(metconDescription: metconDescription);
        }),
    Routes.metconEdit: (context) => _checkLogin(() {
          final metconDescription =
              ModalRoute.of(context)?.settings.arguments as MetconDescription?;
          return MetconEditPage(metconDescription: metconDescription);
        }),
    // metcon session
    Routes.metconSessionOverview: (_) => _checkLogin(MetconSessionsPage.new),
    Routes.metconSessionDetails: (context) => _checkLogin(() {
          final metconSessionDescription = ModalRoute.of(context)!
              .settings
              .arguments! as MetconSessionDescription;
          return MetconSessionDetailsPage(
            metconSessionDescription: metconSessionDescription,
          );
        }),
    Routes.metconSessionEdit: (context) => _checkLogin(() {
          final arg = ModalRoute.of(context)?.settings.arguments;
          final bool isNew;
          final MetconSessionDescription? metconSessionDescription;
          if (arg is MetconSessionDescription) {
            metconSessionDescription = arg;
            isNew = false;
          } else if (arg is MetconDescription) {
            metconSessionDescription = MetconSessionDescription.defaultValue()
              ?..metconDescription = arg
              ..metconSession.metconId = arg.metcon.id;
            isNew = true;
          } else {
            metconSessionDescription = MetconSessionDescription.defaultValue();
            isNew = true;
          }
          return metconSessionDescription == null
              ? const MetconEditPage(metconDescription: null)
              : MetconSessionEditPage(
                  metconSessionDescription: metconSessionDescription,
                  isNew: isNew,
                );
        }),
    // route
    Routes.routeOverview: (_) => _checkLogin(RoutePage.new),
    Routes.routeDetails: (context) => _checkLogin(() {
          final route = ModalRoute.of(context)!.settings.arguments! as Route;
          return RouteDetailsPage(route: route);
        }),
    Routes.routeEdit: (context) => _checkLogin(() {
          final route = ModalRoute.of(context)?.settings.arguments as Route?;
          return RouteEditPage(
            route: route,
          );
        }),
    Routes.routeUpload: (_) => _checkLogin(() => const RouteUploadPage()),
    // cardio
    Routes.cardioOverview: (_) => _checkLogin(CardioSessionsPage.new),
    Routes.cardioDetails: (context) => _checkLogin(() {
          final cardioSessionDescription = ModalRoute.of(context)!
              .settings
              .arguments! as CardioSessionDescription;
          return CardioDetailsPage(
            cardioSessionDescription: cardioSessionDescription,
          );
        }),
    Routes.cardioEdit: (context) => _checkLogin(() {
          var isNew = false;
          var cardioSessionDescription = ModalRoute.of(context)
              ?.settings
              .arguments as CardioSessionDescription?;
          if (cardioSessionDescription == null) {
            cardioSessionDescription = CardioSessionDescription.defaultValue();
            isNew = true;
          }
          return cardioSessionDescription == null
              ? const MovementEditPage(movementDescription: null)
              : CardioEditPage(
                  cardioSessionDescription: cardioSessionDescription,
                  isNew: isNew,
                );
        }),
    Routes.trackingSettings: (context) => _checkLoginAndroidIos(
          context,
          () => const CardioTrackingSettingsPage(),
        ),
    Routes.tracking: (context) => _checkLoginAndroidIos(context, () {
          final args =
              ModalRoute.of(context)!.settings.arguments! as List<dynamic>;
          return CardioTrackingPage(
            movement: args[0] as Movement,
            cardioType: args[1] as CardioType,
            route: args[2] as Route?,
            heartRateUtils: args[3] as HeartRateUtils?,
          );
        }),
    // diary
    Routes.diaryOverview: (_) => _checkLogin(DiaryPage.new),
    Routes.diaryEdit: (context) => _checkLogin(() {
          final diary = ModalRoute.of(context)?.settings.arguments as Diary?;
          return DiaryEditPage(diary: diary);
        })
  };

  static Map<String, Widget Function(BuildContext)> get all => _routeList;

  static Widget Function(BuildContext) get(String routeName) =>
      _routeList[routeName]!;
}
