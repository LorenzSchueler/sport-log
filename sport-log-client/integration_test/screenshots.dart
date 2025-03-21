import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/src/channel.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/main.dart';
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
import 'package:sport_log/pages/settings/about_page.dart';
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
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/main_drawer.dart';

// ignore: unreachable_from_main
final logger = Logger("Screenshot");

// TODO: Change when fixed: https://github.com/flutter/flutter/issues/92381
// final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

const serverUrl = "http://10.0.2.2:8001";
const username = "ScreenshotUser";
const password = "ScreenshotPassword0";

Finder input(String text) =>
    find.ancestor(of: find.text(text), matching: find.byType(TextFormField));
final serverUrlInput = input("Server URL");
final usernameInput = input("Username");
final passwordInput = input("Password");

Finder button(String text) =>
    find.ancestor(of: find.text(text), matching: find.byType(FilledButton));
final loginButton = button("Login");
final okButton = button("OK");
final cancelButton = button("Cancel");

final aboutButton = find.ancestor(
  of: find.text("About", skipOffstage: false),
  matching: find.byType(ElevatedButton, skipOffstage: false),
);

Finder fab(IconData icon) => find.ancestor(
  of: find.byIcon(icon),
  matching: find.byType(FloatingActionButton),
);
final addFab = fab(AppIcons.add);
final stopwatchFab = fab(AppIcons.stopwatch);
final routeFab = fab(AppIcons.route);
final uploadFab = fab(AppIcons.upload);
final layersFab = fab(AppIcons.layers);

final backButton = find.byType(BackButton);

Finder iconButton(IconData icon) =>
    find.ancestor(of: find.byIcon(icon), matching: find.byType(IconButton));
final menuButton = iconButton(Icons.menu);
final routeButton = iconButton(AppIcons.route);
final editButton = iconButton(AppIcons.edit);
final cutButton = iconButton(AppIcons.cut);
final elevationButton = iconButton(AppIcons.trendingUp);

final discardChanges = find.ancestor(
  of: find.text("Discard Changes"),
  matching: find.byType(TextButton),
);

Finder navItem(String text) => find.ancestor(
  of: find.text(text),
  matching: find.byType(NavigationDestination),
);
final strengthNavItem = navItem("Strength");
final metconNavItem = navItem("Metcon");
final cardioNavItem = navItem("Cardio");
final wodNavItem = navItem("Wod");
final diaryNavItem = navItem("Diary");

Finder drawerItem(String text) =>
    find.ancestor(of: find.text(text), matching: find.byType(ListTile));
final movementDrawerItem = drawerItem("Movements");
final timerDrawerItem = drawerItem("Timer");
final mapDrawerItem = drawerItem("Map");
final offlineMapsDrawerItem = drawerItem("Offline Maps");
final heartRateDrawerItem = drawerItem("Heart Rate");
final serverActionsDrawerItem = drawerItem("Server Actions");
final settingsDrawerItem = drawerItem("Settings");

Future<void> backDiscardChanges(WidgetTester tester) async {
  await tap(tester, backButton);
  await tap(tester, discardChanges);
}

Future<void> openDrawer(WidgetTester tester) async {
  await tap(tester, menuButton);
  expect(find.byType(MainDrawer), findsOneWidget);
}

Future<void> waitMapRender(WidgetTester tester) =>
    tester.pumpAndSettle(const Duration(seconds: 10));

Future<void> tap(
  WidgetTester tester,
  Finder finder, {
  bool warnIfMissed = true,
}) async {
  expect(finder, findsOneWidget);
  await tester.tap(finder, warnIfMissed: warnIfMissed);
  await tester.pumpAndSettle();
}

Future<void> enterText(WidgetTester tester, Finder finder, String text) async {
  expect(finder, findsOneWidget);
  await tester.enterText(finder, text);
  await tester.pumpAndSettle();
}

Future<void> screenshot(WidgetTester tester, String filename) async {
  if (Platform.isAndroid) {
    await integrationTestChannel.invokeMethod<void>(
      'convertFlutterSurfaceToImage',
    );
    // TODO: Change when fixed: https://github.com/flutter/flutter/issues/92381
    // await binding.convertFlutterSurfaceToImage();
  }

  await tester.pumpAndSettle();

  integrationTestChannel.setMethodCallHandler((call) async {
    switch (call.method) {
      case 'scheduleFrame':
        PlatformDispatcher.instance.scheduleFrame();
        break;
    }
    return null;
  });
  final rawBytes = await integrationTestChannel.invokeMethod<List<int>>(
    'captureScreenshot',
    <String, dynamic>{'name': "screenshot.png"},
  );
  final bytes = rawBytes!;

  // TODO: Change when fixed: https://github.com/flutter/flutter/issues/92381
  // final bytes = await binding.takeScreenshot("screenshot.png");
  final image = Uint8List.fromList(bytes);
  const dir = '/storage/emulated/0/Download';
  final file = File("$dir/$filename.png");
  await file.writeAsBytes(image, flush: true, mode: FileMode.writeOnly);
  logger.i(file);

  if (Platform.isAndroid) {
    await integrationTestChannel.invokeMethod<void>('revertFlutterImage');
    // TODO: Change when fixed: https://github.com/flutter/flutter/issues/92381
    // await binding.revertFlutterImage();
  }
}

// ignore: long-method
void main() {
  testWidgets('screenshots', (tester) async {
    // do not use app.main() to avoid GlobalErrorHandler
    runApp(const InitAppWrapper());

    // landing
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.byType(LandingPage), findsOneWidget);
    await screenshot(tester, "landing");

    // go to login
    await tap(tester, loginButton);
    expect(find.byType(LoginPage), findsOneWidget);
    await screenshot(tester, "login");

    // login and go to timeline
    await enterText(tester, serverUrlInput, serverUrl);
    await enterText(tester, usernameInput, username);
    await enterText(tester, passwordInput, password);
    await tap(tester, loginButton);
    expect(find.byType(TimelinePage), findsOneWidget);
    await waitMapRender(tester);
    await screenshot(tester, "timeline");

    // go to strength overview
    expect(strengthNavItem, findsOneWidget);
    await tap(tester, strengthNavItem);
    expect(find.byType(StrengthOverviewPage), findsOneWidget);
    await screenshot(tester, "strength_overview");

    // go to strength details
    await tap(tester, find.byType(StrengthSessionCard).first);
    expect(find.byType(StrengthSessionDetailsPage), findsOneWidget);
    await screenshot(tester, "strength_details");

    // go to strength edit
    await tap(tester, editButton);
    expect(find.byType(StrengthEditPage), findsOneWidget);
    await screenshot(tester, "strength_edit");
    await backDiscardChanges(tester); // back to details
    await tap(tester, backButton); // back to overview

    // go to metcon session overview
    await tap(tester, metconNavItem);
    expect(find.byType(MetconSessionOverviewPage), findsOneWidget);
    await screenshot(tester, "metcon_session_overview");

    // go to metcon session details
    await tap(tester, find.byType(MetconSessionCard).first);
    expect(find.byType(MetconSessionDetailsPage), findsOneWidget);
    await tester.pumpAndSettle(); // wait for other sessions to load
    await screenshot(tester, "metcon_session_details");

    // go to metcon session edit
    await tap(tester, editButton);
    expect(find.byType(MetconSessionEditPage), findsOneWidget);
    await screenshot(tester, "metcon_session_edit");
    await backDiscardChanges(tester); // back to details
    await tap(tester, backButton); // back to overview

    // go to metcon overview
    final metconButton = find.ancestor(
      of: find.byIcon(AppIcons.notes),
      matching: find.byType(IconButton),
    );
    await tap(tester, metconButton);
    expect(find.byType(MetconOverviewPage), findsOneWidget);
    await tester.pumpAndSettle(); // wait for data to load
    await screenshot(tester, "metcon_overview");

    await tap(tester, find.byType(MetconCard).first);
    expect(find.byType(MetconDetailsPage), findsOneWidget);
    await screenshot(tester, "metcon_details");
    await tap(tester, backButton);

    // go to metcon edit
    await tap(tester, addFab);
    expect(find.byType(MetconEditPage), findsOneWidget);
    await screenshot(tester, "metcon_edit");
    await backDiscardChanges(tester);

    // go to cardio overview
    await tap(tester, cardioNavItem);
    expect(find.byType(CardioOverviewPage), findsOneWidget);
    await waitMapRender(tester);
    await screenshot(tester, "cardio_overview");

    // go to cardio details
    await tap(tester, find.textContaining(" at ").first);
    // await tap(tester, find.byType(CardioSessionCard).first); // tap not registered
    expect(find.byType(CardioDetailsPage), findsOneWidget);
    await waitMapRender(tester);
    await screenshot(tester, "cardio_details");

    // go to cardio edit
    await tap(tester, editButton);
    expect(find.byType(CardioEditPage), findsOneWidget);
    await waitMapRender(tester);
    await screenshot(tester, "cardio_edit");

    // go to cardio cut
    await tap(tester, cutButton);
    expect(find.byType(CardioCutPage), findsOneWidget);
    await waitMapRender(tester);
    await screenshot(tester, "cardio_cut");
    await backDiscardChanges(tester); // back to edit

    // go to cardio update elevation
    await tap(tester, elevationButton);
    expect(find.byType(CardioUpdateElevationPage), findsOneWidget);
    await screenshot(tester, "cardio_update_elevation");
    await backDiscardChanges(tester); // back to edit
    await backDiscardChanges(tester); // back to details
    await tap(tester, backButton); // back to overview

    // go to tracking settings
    await tap(tester, addFab);
    await tap(tester, stopwatchFab);
    expect(find.byType(CardioTrackingSettingsPage), findsOneWidget);
    await screenshot(tester, "tracking_settings");

    // go to tracking
    await tap(tester, okButton);
    expect(find.byType(CardioTrackingPage), findsOneWidget);
    await waitMapRender(tester);
    await screenshot(tester, "tracking");
    await tap(tester, cancelButton); // back to tracking settings
    await tap(tester, backButton); // back to cardio overview

    // go to route overview
    await tap(tester, routeButton);
    expect(find.byType(RouteOverviewPage), findsOneWidget);
    await waitMapRender(tester);
    await screenshot(tester, "route_overview");

    // go to route details
    await tap(tester, find.textContaining("km", findRichText: true).first);
    // await tap(tester, find.byType(RouteCard).first); // tap not registered
    expect(find.byType(RouteDetailsPage), findsOneWidget);
    await waitMapRender(tester);
    await screenshot(tester, "route_details");
    await tap(tester, backButton); // back to route overview

    // go to route edit
    await tap(tester, addFab);
    await tap(tester, routeFab);
    expect(find.byType(RouteEditPage), findsOneWidget);
    await waitMapRender(tester);
    await screenshot(tester, "route_edit");
    await backDiscardChanges(tester);

    // go to route upload
    await tap(tester, addFab);
    await tap(tester, uploadFab);
    expect(find.byType(RouteUploadPage), findsOneWidget);
    await waitMapRender(tester);
    await screenshot(tester, "route_upload");
    await backDiscardChanges(tester);

    // go to wod overview
    await tap(tester, wodNavItem);
    expect(find.byType(WodOverviewPage), findsOneWidget);
    await screenshot(tester, "wod_overview");

    // go to wod session edit
    await tap(tester, find.byType(WodCard).first);
    expect(find.byType(WodEditPage), findsOneWidget);
    await screenshot(tester, "wod_edit");
    await backDiscardChanges(tester);

    // go to diary overview
    await tap(tester, diaryNavItem);
    expect(find.byType(DiaryOverviewPage), findsOneWidget);
    await screenshot(tester, "diary_overview");

    // go to diary session edit
    await tap(tester, find.byType(DiaryCard).first);
    expect(find.byType(DiaryEditPage), findsOneWidget);
    await screenshot(tester, "diary_edit");
    await backDiscardChanges(tester);

    // open drawer
    await openDrawer(tester);
    expect(find.byType(MainDrawer), findsOneWidget);
    await screenshot(tester, "drawer");

    // go to movement overview
    await tap(tester, movementDrawerItem);
    expect(find.byType(MovementOverviewPage), findsOneWidget);
    await screenshot(tester, "movement_overview");

    // go to movement edit
    await tap(tester, addFab);
    await screenshot(tester, "movement_edit");
    expect(find.byType(MovementEditPage), findsOneWidget);
    await backDiscardChanges(tester);

    // go to timer
    await openDrawer(tester);
    await tap(tester, timerDrawerItem);
    expect(find.byType(TimerPage), findsOneWidget);
    await screenshot(tester, "timer");

    // go to map
    await openDrawer(tester);
    await tap(tester, mapDrawerItem);
    expect(find.byType(MapPage), findsOneWidget);
    await waitMapRender(tester);
    await screenshot(tester, "map");

    await tap(tester, layersFab);
    await screenshot(tester, "map_styles");

    await tap(
      tester,
      //find.descendant(
      //of: find.byType(SegmentedButton),
      //matching:
      find.byIcon(AppIcons.satellite),
      //),
    );
    await tap(tester, layersFab, warnIfMissed: false); // hide map style sheet
    await waitMapRender(tester);
    await screenshot(tester, "map_satellite");

    // go to offline maps
    await openDrawer(tester);
    await tap(tester, offlineMapsDrawerItem);
    expect(find.byType(OfflineMapsPage), findsOneWidget);
    await waitMapRender(tester);
    await screenshot(tester, "offline_maps");

    // go to heart rate
    await openDrawer(tester);
    await tap(tester, heartRateDrawerItem);
    expect(find.byType(HeartRatePage), findsOneWidget);
    await screenshot(tester, "heart_rate");

    // go to platform_overview
    await openDrawer(tester);
    await tap(tester, serverActionsDrawerItem);
    expect(find.byType(PlatformOverviewPage), findsOneWidget);
    await screenshot(tester, "platform_overview");

    // go to action provider overview
    await tap(tester, find.text("wodify-login"));
    expect(find.byType(ActionProviderOverviewPage), findsOneWidget);
    await tester.pumpAndSettle(); // wait for data to load
    await screenshot(tester, "action_provider_overview");

    // go to action rule edit
    await tap(
      tester,
      find
          .descendant(
            of: find.byType(ActionRulesCard),
            matching: find.text("CrossFit"),
          )
          .first,
    );
    expect(find.byType(ActionRuleEditPage), findsOneWidget);
    await screenshot(tester, "action_rule_edit");
    await backDiscardChanges(tester); // back to ap overview

    // go to action event edit
    await tap(
      tester,
      find
          .descendant(
            of: find.byType(ActionEventsCard),
            matching: find.text("CrossFit"),
          )
          .first,
    );
    expect(find.byType(ActionEventEditPage), findsOneWidget);
    await screenshot(tester, "action_event_edit");
    await backDiscardChanges(tester); // back to ap overview
    await tap(tester, backButton); // back to platform overview

    // go to settings
    await openDrawer(tester);
    await tap(tester, settingsDrawerItem);
    expect(find.byType(SettingsPage), findsOneWidget);
    await screenshot(tester, "settings");

    // go to about
    expect(aboutButton, findsOneWidget);
    await tester.ensureVisible(aboutButton);
    await tester.pumpAndSettle();
    await tap(tester, aboutButton);
    expect(find.byType(AboutPage), findsOneWidget);
    await screenshot(tester, "about");
  });
}
