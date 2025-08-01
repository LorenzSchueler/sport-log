import 'package:flutter/material.dart' hide Route;
import 'package:sport_log/config.dart';
import 'package:sport_log/models/action/action_provider_description.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/pages/action/action_event_edit_page.dart';
import 'package:sport_log/pages/action/action_provider_overview_page.dart';
import 'package:sport_log/pages/action/action_rule_edit_page.dart';
import 'package:sport_log/pages/action/platform_overview_page.dart';
import 'package:sport_log/pages/heart_rate/heart_rate_page.dart';
import 'package:sport_log/pages/login/landing_page.dart';
import 'package:sport_log/pages/login/login_page.dart';
import 'package:sport_log/pages/login/update_page.dart';
import 'package:sport_log/pages/map/map_page.dart';
import 'package:sport_log/pages/movements/movement_edit_page.dart';
import 'package:sport_log/pages/movements/movement_overview_page.dart';
import 'package:sport_log/pages/offline_maps/offline_maps_overview.dart';
import 'package:sport_log/pages/platform_not_supported_page.dart';
import 'package:sport_log/pages/settings/about_page.dart';
import 'package:sport_log/pages/settings/dev_status_page.dart';
import 'package:sport_log/pages/settings/dev_tools_page.dart';
import 'package:sport_log/pages/settings/settings_page.dart';
import 'package:sport_log/pages/timer/timer_page.dart';
import 'package:sport_log/pages/workout/cardio/cardio_cut_page.dart';
import 'package:sport_log/pages/workout/cardio/cardio_details_page.dart';
import 'package:sport_log/pages/workout/cardio/cardio_edit_page.dart';
import 'package:sport_log/pages/workout/cardio/cardio_overview_page.dart';
import 'package:sport_log/pages/workout/cardio/cardio_update_elevation_page.dart';
import 'package:sport_log/pages/workout/cardio/route_details_page.dart';
import 'package:sport_log/pages/workout/cardio/route_edit_page.dart';
import 'package:sport_log/pages/workout/cardio/route_overview_page.dart';
import 'package:sport_log/pages/workout/cardio/route_upload_page.dart';
import 'package:sport_log/pages/workout/cardio/tracking_page.dart';
import 'package:sport_log/pages/workout/cardio/tracking_settings.dart';
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
import 'package:sport_log/pages/workout/wod/wod_edit_page.dart';
import 'package:sport_log/pages/workout/wod/wod_overview_page.dart';
import 'package:sport_log/settings.dart';

abstract class Routes {
  static const landing = '/landing';
  static const login = '/login';
  static const registration = '/register';
  static const update = '/update';
  static const timer = "/timer";
  static const map = "/map";
  static const offlineMaps = "/offline_maps";
  static const heartRate = "/heart_rate";
  static const settings = "/settings";
  static const devStatus = "/dev_status";
  static const devTools = "/dev_tools";
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
  static const String cardioUpdateElevation = '/cardio/update_elevation';
  static const String cardioCut = '/cardio/cut';
  static const String trackingSettings = '/cardio/tracking_settings';
  static const String tracking = '/cardio/tracking';
  // wod
  static const String wodOverview = '/wod/overview';
  static const String wodEdit = '/wod/edit';
  // diary
  static const String diaryOverview = '/diary/overview';
  static const String diaryEdit = '/diary/edit';

  /// userId is set after the user has registered/ logged in/ chosen to use without account.
  static Widget _checkUserId(Widget Function() builder) {
    return Settings.instance.userId != null ? builder() : const LandingPage();
  }

  static Widget _checkUserIdAndroidIos(
    BuildContext context,
    Widget Function() builder,
  ) {
    return Settings.instance.userId != null
        ? Config.isAndroid || Config.isIOS
              ? builder()
              : const PlatformNotSupportedPage()
        : const LandingPage();
  }

  static Widget _checkNotUserId(Widget Function() builder) {
    return Settings.instance.userId == null ? builder() : TimelinePage();
  }

  static Widget _checkNoAccount(Widget Function() builder) {
    return Settings.instance.accountCreated ? TimelinePage() : builder();
  }

  static final Map<String, Widget Function(BuildContext)> _routeList = {
    Routes.landing: (_) => _checkNotUserId(() => const LandingPage()),
    Routes.login: (_) =>
        _checkNoAccount(() => const LoginPage(loginType: LoginType.login)),
    Routes.registration: (_) =>
        _checkNoAccount(() => const LoginPage(loginType: LoginType.register)),
    Routes.update: (_) => const UpdatePage(),
    Routes.timer: (_) => _checkUserId(() => const TimerPage()),
    Routes.map: (context) => _checkUserIdAndroidIos(context, MapPage.new),
    Routes.offlineMaps: (context) =>
        _checkUserIdAndroidIos(context, () => const OfflineMapsPage()),
    Routes.heartRate: (context) =>
        _checkUserIdAndroidIos(context, () => const HeartRatePage()),
    Routes.settings: (_) => _checkUserId(() => const SettingsPage()),
    Routes.devStatus: (_) => _checkUserId(() => const DevStatusPage()),
    Routes.devTools: (_) => _checkUserId(() => const DevToolsPage()),
    Routes.about: (_) => _checkUserId(() => const AboutPage()),
    // platform & ap
    Routes.platformOverview: (_) =>
        _checkUserId(() => const PlatformOverviewPage()),
    Routes.actionProviderOverview: (context) => _checkUserId(() {
      final actionProvider =
          ModalRoute.of(context)!.settings.arguments! as ActionProvider;
      return ActionProviderOverviewPage(actionProvider: actionProvider);
    }),
    Routes.actionRuleEdit: (context) => _checkUserId(() {
      final args = ModalRoute.of(context)!.settings.arguments! as List<dynamic>;
      return ActionRuleEditPage(
        actionProviderDescription: args[0] as ActionProviderDescription,
        actionRule: args[1] as ActionRule?,
      );
    }),
    Routes.actionEventEdit: (context) => _checkUserId(() {
      final args = ModalRoute.of(context)!.settings.arguments! as List<dynamic>;
      return ActionEventEditPage(
        actionProviderDescription: args[0] as ActionProviderDescription,
        actionEvent: args[1] as ActionEvent?,
      );
    }),
    // movement
    Routes.movementOverview: (_) => _checkUserId(MovementOverviewPage.new),
    Routes.movementEdit: (context) => _checkUserId(() {
      final arg = ModalRoute.of(context)?.settings.arguments;
      if (arg is MovementDescription) {
        return MovementEditPage(movementDescription: arg);
      } else if (arg is String) {
        return MovementEditPage.fromName(name: arg);
      }
      return const MovementEditPage(movementDescription: null);
    }),
    // timeline
    Routes.timelineOverview: (_) => _checkUserId(TimelinePage.new),
    // strength
    Routes.strengthOverview: (_) => _checkUserId(StrengthOverviewPage.new),
    Routes.strengthDetails: (context) => _checkUserId(() {
      final strengthSessionDescription =
          ModalRoute.of(context)!.settings.arguments!
              as StrengthSessionDescription;
      return StrengthSessionDetailsPage(
        strengthSessionDescription: strengthSessionDescription,
      );
    }),
    Routes.strengthEdit: (context) => _checkUserId(() {
      final arg = ModalRoute.of(context)?.settings.arguments;
      final bool isNew;
      final StrengthSessionDescription? strengthSessionDescription;
      if (arg is StrengthSessionDescription) {
        strengthSessionDescription = arg;
        isNew = false;
      } else if (arg is Movement) {
        strengthSessionDescription = StrengthSessionDescription.defaultValue()
          ?..movement = arg
          ..session.movementId = arg.id;
        isNew = true;
      } else {
        strengthSessionDescription = StrengthSessionDescription.defaultValue();
        isNew = true;
      }
      return strengthSessionDescription == null
          ? const MovementEditPage(movementDescription: null)
          : StrengthEditPage(
              strengthSessionDescription: strengthSessionDescription,
              isNew: isNew,
            );
    }),
    // metcon
    Routes.metconOverview: (_) => _checkUserId(MetconOverviewPage.new),
    Routes.metconDetails: (context) => _checkUserId(() {
      final metconDescription =
          ModalRoute.of(context)!.settings.arguments! as MetconDescription;
      return MetconDetailsPage(metconDescription: metconDescription);
    }),
    Routes.metconEdit: (context) => _checkUserId(() {
      final metconDescription =
          ModalRoute.of(context)?.settings.arguments as MetconDescription?;
      return MetconEditPage(metconDescription: metconDescription);
    }),
    // metcon session
    Routes.metconSessionOverview: (_) =>
        _checkUserId(MetconSessionOverviewPage.new),
    Routes.metconSessionDetails: (context) => _checkUserId(() {
      final metconSessionDescription =
          ModalRoute.of(context)!.settings.arguments!
              as MetconSessionDescription;
      return MetconSessionDetailsPage(
        metconSessionDescription: metconSessionDescription,
      );
    }),
    Routes.metconSessionEdit: (context) => _checkUserId(() {
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
    Routes.routeOverview: (_) => _checkUserId(RouteOverviewPage.new),
    Routes.routeDetails: (context) => _checkUserId(() {
      final route = ModalRoute.of(context)!.settings.arguments! as Route;
      return RouteDetailsPage(route: route);
    }),
    Routes.routeEdit: (context) => _checkUserId(() {
      final route = ModalRoute.of(context)?.settings.arguments as Route?;
      return RouteEditPage(route: route);
    }),
    Routes.routeUpload: (_) => _checkUserId(() => const RouteUploadPage()),
    // cardio
    Routes.cardioOverview: (_) => _checkUserId(CardioOverviewPage.new),
    Routes.cardioDetails: (context) => _checkUserId(() {
      final cardioSessionDescription =
          ModalRoute.of(context)!.settings.arguments!
              as CardioSessionDescription;
      return CardioDetailsPage(
        cardioSessionDescription: cardioSessionDescription,
      );
    }),
    Routes.cardioEdit: (context) => _checkUserId(() {
      final arg = ModalRoute.of(context)?.settings.arguments;
      final bool isNew;
      final CardioSessionDescription? cardioSessionDescription;
      if (arg is CardioSessionDescription) {
        cardioSessionDescription = arg;
        isNew = false;
      } else if (arg is Movement) {
        cardioSessionDescription = CardioSessionDescription.defaultValue()
          ?..movement = arg
          ..cardioSession.movementId = arg.id;
        isNew = true;
      } else {
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
    Routes.cardioUpdateElevation: (context) => _checkUserId(() {
      final cardioSessionDescription =
          ModalRoute.of(context)!.settings.arguments!
              as CardioSessionDescription;
      return CardioUpdateElevationPage(
        cardioSessionDescription: cardioSessionDescription,
      );
    }),
    Routes.cardioCut: (context) => _checkUserId(() {
      final cardioSessionDescription =
          ModalRoute.of(context)!.settings.arguments!
              as CardioSessionDescription;
      return CardioCutPage(cardioSessionDescription: cardioSessionDescription);
    }),
    Routes.trackingSettings: (context) => _checkUserIdAndroidIos(context, () {
      final movement =
          ModalRoute.of(context)?.settings.arguments as Movement? ??
          Movement.defaultMovement;
      return movement == null
          ? const MovementEditPage(movementDescription: null)
          : CardioTrackingSettingsPage(initMovement: movement);
    }),
    Routes.tracking: (context) => _checkUserIdAndroidIos(context, () {
      final trackingSettings =
          ModalRoute.of(context)!.settings.arguments! as TrackingSettings;
      return CardioTrackingPage(trackingSettings: trackingSettings);
    }),
    // wod
    Routes.wodOverview: (_) => _checkUserId(WodOverviewPage.new),
    Routes.wodEdit: (context) => _checkUserId(() {
      final wod = ModalRoute.of(context)?.settings.arguments as Wod?;
      return WodEditPage(wod: wod);
    }),
    // diary
    Routes.diaryOverview: (_) => _checkUserId(DiaryOverviewPage.new),
    Routes.diaryEdit: (context) => _checkUserId(() {
      final diary = ModalRoute.of(context)?.settings.arguments as Diary?;
      return DiaryEditPage(diary: diary);
    }),
  };

  static Map<String, Widget Function(BuildContext)> get all => _routeList;

  static Widget Function(BuildContext) get(String routeName) =>
      _routeList[routeName]!;
}
