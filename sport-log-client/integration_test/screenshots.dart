import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/main.dart';
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
import 'package:sport_log/pages/workout/cardio/cardio_edit_page.dart';
import 'package:sport_log/pages/workout/cardio/cardio_overview_page.dart';
import 'package:sport_log/pages/workout/cardio/route_edit_page.dart';
import 'package:sport_log/pages/workout/cardio/route_overview_page.dart';
import 'package:sport_log/pages/workout/cardio/route_upload_page.dart';
import 'package:sport_log/pages/workout/cardio/tracking_page.dart';
import 'package:sport_log/pages/workout/cardio/tracking_settings_page.dart';
import 'package:sport_log/pages/workout/diary/diary_edit_page.dart';
import 'package:sport_log/pages/workout/diary/diary_overview_page.dart';
import 'package:sport_log/pages/workout/metcon_sessions/metcon_edit_page.dart';
import 'package:sport_log/pages/workout/metcon_sessions/metcon_overview_page.dart';
import 'package:sport_log/pages/workout/metcon_sessions/metcon_session_edit_page.dart';
import 'package:sport_log/pages/workout/metcon_sessions/metcon_session_overview_page.dart';
import 'package:sport_log/pages/workout/strength_sessions/strength_edit_page.dart';
import 'package:sport_log/pages/workout/strength_sessions/strength_overview_page.dart';
import 'package:sport_log/pages/workout/timeline/timeline_page.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/main_drawer.dart';

final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

const serverUrl = "http://10.0.2.2:8001";
const username = "uq";
const password = "123456aBC";
const mapPumpDuration = Duration(seconds: 5);

Finder input(String text) => find.ancestor(
      of: find.text(text),
      matching: find.byType(TextFormField),
    );
final serverUrlInput = input("Server URL");
final usernameInput = input("Username");
final passwordInput = input("Password");

Finder button(String text) => find.ancestor(
      of: find.text(text),
      matching: find.byType(ElevatedButton),
    );
final loginButton = button("Login");
final okButton = button("OK");
final cancelButton = button("Cancel");

final aboutButton = find.ancestor(
  of: find.text("About", skipOffstage: false),
  matching: find.byType(OutlinedButton, skipOffstage: false),
);

Finder fab(IconData icon) => find.ancestor(
      of: find.byIcon(icon),
      matching: find.byType(FloatingActionButton),
    );
final addFab = fab(AppIcons.add);
final editFab = fab(AppIcons.notes);
final stopwatchFab = fab(AppIcons.stopwatch);
final routeFab = fab(AppIcons.route);
final uploadFab = fab(AppIcons.upload);

final backButton = find.byType(BackButton);

final menuButton = find.ancestor(
  of: find.byIcon(Icons.menu),
  matching: find.byType(IconButton),
);

final routeButton = find.ancestor(
  of: find.byIcon(AppIcons.route),
  matching: find.byType(IconButton),
);

final discardChanges = find.ancestor(
  of: find.text("Discard Changes"),
  matching: find.byType(TextButton),
);

Finder navItem(String text) => find.ancestor(
      of: find.text(text),
      matching: find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == "_BottomNavigationTile",
      ),
    );
final strengthNavItem = navItem("Strength");
final metconNavItem = navItem("Metcon");
final cardioNavItem = navItem("Cardio");
final diaryNavItem = navItem("Diary");

Finder drawerItem(String text) => find.ancestor(
      of: find.text(text),
      matching: find.byType(ListTile),
    );
final movementDrawerItem = drawerItem("Movements");
final timerDrawerItem = drawerItem("Timer");
final mapDrawerItem = drawerItem("Map");
final offlineMapsDrawerItem = drawerItem("Offline Maps");
final heartRateDrawerItem = drawerItem("Heart Rate");
final serverActionsDrawerItem = drawerItem("Server Actions");
final settingsDrawerItem = drawerItem("Settings");

// ignore: unreachable_from_main
void printAncestors(Finder finder) {
  finder.evaluate().first.visitAncestorElements((element) {
    logInfo("widget: ${element.widget.runtimeType}");
    return true;
  });
}

Future<void> backDiscardChanges(WidgetTester tester) async {
  await tap(tester, backButton);
  await tap(tester, discardChanges);
}

Future<void> openDrawer(WidgetTester tester) async {
  await tap(tester, menuButton);
  expect(find.byType(MainDrawer), findsOneWidget);
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  expect(finder, findsOneWidget);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> enterText(WidgetTester tester, Finder finder, String text) async {
  expect(finder, findsOneWidget);
  await tester.enterText(finder, text);
  await tester.pumpAndSettle();
}

Future<void> screenshot(String filename) async {
  //if (Config.isAndroid) {
  //await binding.convertFlutterSurfaceToImage();
  //}
  final image =
      Uint8List.fromList(await binding.takeScreenshot("screenshot.png"));
  const dir = '/storage/emulated/0/Download';
  final file = File("$dir/$filename.png");
  await file.writeAsBytes(
    image,
    flush: true,
    mode: FileMode.writeOnly,
  );
  logInfo(file);
  if (Config.isAndroid) {
    //await revertFlutterImage();
  }
}

// ignore: long-method
void main() {
  testWidgets('screenshots', (tester) async {
    // do not use app.main() to avoid GlobalErrorHandler
    runApp(const InitAppWrapper());

    // TODO
    if (Config.isAndroid) {
      await binding.convertFlutterSurfaceToImage();
    }

    // landing
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.byType(LandingPage), findsOneWidget);
    await screenshot("landing");

    // go to login
    await tap(tester, loginButton);
    expect(find.byType(LoginPage), findsOneWidget);
    await screenshot("login");

    // login and go to timeline
    await enterText(tester, serverUrlInput, serverUrl);
    await enterText(tester, usernameInput, username);
    await enterText(tester, passwordInput, password);
    await tap(tester, loginButton);
    expect(find.byType(TimelinePage), findsOneWidget);
    await tester.pumpAndSettle(mapPumpDuration); // wait for map to render
    await screenshot("timeline");

    // go to strength overview
    expect(strengthNavItem, findsOneWidget);
    await tap(tester, strengthNavItem);
    expect(find.byType(StrengthOverviewPage), findsOneWidget);
    await screenshot("strength_session_overview");

    // go to strength details TODO

    // go to strength edit
    await tap(tester, addFab);
    expect(find.byType(StrengthEditPage), findsOneWidget);
    await screenshot("strength_session_edit");
    await backDiscardChanges(tester);

    // go to metcon session overview
    await tap(tester, metconNavItem);
    expect(find.byType(MetconSessionOverviewPage), findsOneWidget);
    await screenshot("metcon_session_overview");

    // go to metcon session details TODO

    // go to metcon session edit
    await tap(tester, addFab);
    expect(find.byType(MetconSessionEditPage), findsOneWidget);
    await screenshot("metcon_session_edit");
    await backDiscardChanges(tester);

    // go to metcon overview
    final metconButton = find.ancestor(
      of: find.byIcon(AppIcons.notes),
      matching: find.byType(IconButton),
    );
    await tap(tester, metconButton);
    expect(find.byType(MetconOverviewPage), findsOneWidget);
    await screenshot("metcon_overview");

    // go to metcon details TODO

    // go to metcon edit
    await tap(tester, addFab);
    expect(find.byType(MetconEditPage), findsOneWidget);
    await screenshot("metcon_edit");
    await backDiscardChanges(tester);

    // go to cardio overview
    await tap(tester, cardioNavItem);
    expect(find.byType(CardioOverviewPage), findsOneWidget);
    await tester.pumpAndSettle(mapPumpDuration); // wait for map to render
    await screenshot("cardio_session_overview");

    // go to cardio details TODO

    // go to cardio edit
    await tap(tester, addFab);
    await tap(tester, editFab);
    expect(find.byType(CardioEditPage), findsOneWidget);
    await tester.pumpAndSettle(mapPumpDuration); // wait for map to render
    await screenshot("cardio_session_edit");
    await backDiscardChanges(tester);

    // go to cardio update elevation TODO
    // go to cardio cut TODO

    // go to tracking settings
    await tap(tester, addFab);
    await tap(tester, stopwatchFab);
    expect(find.byType(CardioTrackingSettingsPage), findsOneWidget);
    await tester.pumpAndSettle(mapPumpDuration); // wait for map to render
    await screenshot("tracking_settings");

    // go to tracking
    await tap(tester, okButton);
    expect(find.byType(CardioTrackingPage), findsOneWidget);
    await tester.pumpAndSettle(mapPumpDuration); // wait for map to render
    await screenshot("tracking");
    await tap(tester, cancelButton); // back to cardio overview
    await tap(tester, backButton); // back to cardio overview

    // go to route overview
    await tap(tester, routeButton);
    expect(find.byType(RouteOverviewPage), findsOneWidget);
    await tester.pumpAndSettle(mapPumpDuration); // wait for map to render
    await screenshot("route_overview");

    // go to route details TODO

    // go to route edit
    await tap(tester, addFab);
    await tap(tester, routeFab);
    expect(find.byType(RouteEditPage), findsOneWidget);
    await tester.pumpAndSettle(mapPumpDuration); // wait for map to render
    await screenshot("route_edit");
    await backDiscardChanges(tester);

    // go to route upload TODO
    await tap(tester, addFab);
    await tap(tester, uploadFab);
    expect(find.byType(RouteUploadPage), findsOneWidget);
    await tester.pumpAndSettle(mapPumpDuration); // wait for map to render
    await screenshot("route_upload");
    await backDiscardChanges(tester);

    // go to diary overview
    await tap(tester, diaryNavItem);
    expect(find.byType(DiaryOverviewPage), findsOneWidget);
    await screenshot("diary_overview");

    // go to diary session edit
    await tap(tester, addFab);
    await screenshot("diary_edit");
    expect(find.byType(DiaryEditPage), findsOneWidget);
    await backDiscardChanges(tester);

    // open drawer
    await openDrawer(tester);
    expect(find.byType(MainDrawer), findsOneWidget);
    await screenshot("drawer");

    // go to movement overview
    await tap(tester, movementDrawerItem);
    expect(find.byType(MovementOverviewPage), findsOneWidget);
    await screenshot("movement_overview");

    // go to movement edit
    await tap(tester, addFab);
    await screenshot("movement_edit");
    expect(find.byType(MovementEditPage), findsOneWidget);
    await backDiscardChanges(tester);

    // go to timer
    await openDrawer(tester);
    await tap(tester, timerDrawerItem);
    expect(find.byType(TimerPage), findsOneWidget);
    await screenshot("timer");

    // go to map
    await openDrawer(tester);
    await tap(tester, mapDrawerItem);
    expect(find.byType(MapPage), findsOneWidget);
    await tester.pumpAndSettle(mapPumpDuration); // wait for map to render
    await screenshot("map");

    // go to offline maps
    await openDrawer(tester);
    await tap(tester, offlineMapsDrawerItem);
    expect(find.byType(OfflineMapsPage), findsOneWidget);
    await tester.pumpAndSettle(mapPumpDuration); // wait for map to render
    await screenshot("offline_maps");

    // go to heart rate
    await openDrawer(tester);
    await tap(tester, heartRateDrawerItem);
    expect(find.byType(HeartRatePage), findsOneWidget);
    await screenshot("heart_rate");

    // go to platform_overview
    await openDrawer(tester);
    await tap(tester, serverActionsDrawerItem);
    expect(find.byType(PlatformOverviewPage), findsOneWidget);
    await screenshot("platform_overview");

    // go to action provider overview TODO
    // go to action rule overview TODO
    // go to action event overview TODO

    // go to settings
    await openDrawer(tester);
    await tap(tester, settingsDrawerItem);
    expect(find.byType(SettingsPage), findsOneWidget);
    await screenshot("settings");

    // go to about
    expect(aboutButton, findsOneWidget);
    await tester.ensureVisible(aboutButton);
    await tester.pumpAndSettle();
    await tap(tester, aboutButton);
    expect(find.byType(AboutPage), findsOneWidget);
    await screenshot("about");
  });
}
