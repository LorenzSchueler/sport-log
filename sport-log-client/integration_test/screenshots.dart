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

Finder input(String name) => find.ancestor(
      of: find.text(name),
      matching: find.byType(TextFormField),
    );
final serverUrlInput = input("Server URL");
final usernameInput = input("Username");
final passwordInput = input("Password");

final loginButton = find.ancestor(
  of: find.text("Login"),
  matching: find.byType(ElevatedButton),
);

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
final routeFab = fab(AppIcons.route);

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

Finder navItem(String name) => find.ancestor(
      of: find.text(name),
      matching: find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == "_BottomNavigationTile",
      ),
    );
final strengthNavItem = navItem("Strength");
final metconNavItem = navItem("Metcon");
final cardioNavItem = navItem("Cardio");
final diaryNavItem = navItem("Diary");

Finder drawerItem(String name) => find.ancestor(
      of: find.text(name),
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
  expect(backButton, findsOneWidget);
  await tester.tap(backButton);
  await tester.pumpAndSettle();
  expect(discardChanges, findsOneWidget);
  await tester.tap(discardChanges);
  await tester.pumpAndSettle();
}

Future<void> openDrawer(WidgetTester tester) async {
  expect(menuButton, findsOneWidget);
  await tester.tap(menuButton);
  await tester.pumpAndSettle();
  expect(find.byType(MainDrawer), findsOneWidget);
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
    expect(loginButton, findsOneWidget);
    await tester.tap(loginButton);
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    await screenshot("login");

    // login and go to timeline
    expect(serverUrlInput, findsOneWidget);
    await tester.enterText(serverUrlInput, serverUrl);
    expect(usernameInput, findsOneWidget);
    await tester.enterText(usernameInput, username);
    expect(passwordInput, findsOneWidget);
    await tester.enterText(passwordInput, password);
    expect(loginButton, findsOneWidget);
    await tester.pumpAndSettle();
    await tester.tap(loginButton);
    await tester.pumpAndSettle();
    expect(find.byType(TimelinePage), findsOneWidget);
    await screenshot("timeline");

    // go to strength overview
    expect(strengthNavItem, findsOneWidget);
    await tester.tap(strengthNavItem);
    await tester.pumpAndSettle();
    expect(find.byType(StrengthOverviewPage), findsOneWidget);
    await screenshot("strength_session_overview");

    // go to strength details TODO

    // go to strength edit
    expect(addFab, findsOneWidget);
    await tester.tap(addFab);
    await tester.pumpAndSettle();
    expect(find.byType(StrengthEditPage), findsOneWidget);
    await screenshot("strength_session_edit");
    await backDiscardChanges(tester);

    // go to metcon session overview
    expect(metconNavItem, findsOneWidget);
    await tester.tap(metconNavItem);
    await tester.pumpAndSettle();
    expect(find.byType(MetconSessionOverviewPage), findsOneWidget);
    await screenshot("metcon_session_overview");

    // go to metcon session details TODO

    // go to metcon session edit
    expect(addFab, findsOneWidget);
    await tester.tap(addFab);
    await tester.pumpAndSettle();
    expect(find.byType(MetconSessionEditPage), findsOneWidget);
    await screenshot("metcon_session_edit");
    await backDiscardChanges(tester);

    // go to metcon overview
    final metconButton = find.ancestor(
      of: find.byIcon(AppIcons.notes),
      matching: find.byType(IconButton),
    );
    expect(metconButton, findsOneWidget);
    await tester.tap(metconButton);
    await tester.pumpAndSettle();
    expect(find.byType(MetconOverviewPage), findsOneWidget);
    await screenshot("metcon_overview");

    // go to metcon details TODO

    // go to metcon edit
    expect(addFab, findsOneWidget);
    await tester.tap(addFab);
    await tester.pumpAndSettle();
    expect(find.byType(MetconEditPage), findsOneWidget);
    await screenshot("metcon_edit");
    await backDiscardChanges(tester);

    // go to cardio overview
    expect(cardioNavItem, findsOneWidget);
    await tester.tap(cardioNavItem);
    await tester.pumpAndSettle(mapPumpDuration);
    expect(find.byType(CardioOverviewPage), findsOneWidget);
    await screenshot("cardio_session_overview");

    // go to cardio details TODO

    // go to cardio edit
    expect(addFab, findsOneWidget);
    await tester.tap(addFab);
    await tester.pumpAndSettle();
    expect(editFab, findsOneWidget);
    await tester.tap(editFab);
    await tester.pumpAndSettle();
    expect(find.byType(CardioEditPage), findsOneWidget);
    await screenshot("cardio_session_edit");
    await backDiscardChanges(tester);

    // go to cardio update elevation TODO
    // go to cardio cut TODO
    // go to tracking settings TODO
    // go to tracking TODO

    // go to route overview
    expect(routeButton, findsOneWidget);
    await tester.tap(routeButton);
    await tester.pumpAndSettle(mapPumpDuration);
    expect(find.byType(RouteOverviewPage), findsOneWidget);
    await screenshot("route_overview");

    // go to route details TODO

    // go to route edit
    expect(addFab, findsOneWidget);
    await tester.tap(addFab);
    await tester.pumpAndSettle();
    expect(routeFab, findsOneWidget);
    await tester.tap(routeFab);
    await tester.pumpAndSettle(mapPumpDuration);
    expect(find.byType(RouteEditPage), findsOneWidget);
    await screenshot("route_edit");
    await backDiscardChanges(tester);

    // go to route upload TODO

    // go to diary overview
    expect(diaryNavItem, findsOneWidget);
    await tester.tap(diaryNavItem);
    await tester.pumpAndSettle();
    expect(find.byType(DiaryOverviewPage), findsOneWidget);
    await screenshot("diary_overview");

    // go to diary session edit
    expect(addFab, findsOneWidget);
    await tester.tap(addFab);
    await tester.pumpAndSettle();
    await screenshot("diary_edit");
    expect(find.byType(DiaryEditPage), findsOneWidget);
    await backDiscardChanges(tester);

    // open drawer
    await openDrawer(tester);
    expect(find.byType(MainDrawer), findsOneWidget);
    await screenshot("drawer");

    // go to movement overview
    expect(movementDrawerItem, findsOneWidget);
    await tester.tap(movementDrawerItem);
    await tester.pumpAndSettle();
    expect(find.byType(MovementOverviewPage), findsOneWidget);
    await screenshot("movement_overview");

    // go to movement edit
    expect(addFab, findsOneWidget);
    await tester.tap(addFab);
    await tester.pumpAndSettle();
    await screenshot("movement_edit");
    expect(find.byType(MovementEditPage), findsOneWidget);
    await backDiscardChanges(tester);

    // go to timer
    await openDrawer(tester);
    expect(timerDrawerItem, findsOneWidget);
    await tester.tap(timerDrawerItem);
    await tester.pumpAndSettle();
    expect(find.byType(TimerPage), findsOneWidget);
    await screenshot("timer");

    // go to map
    await openDrawer(tester);
    expect(mapDrawerItem, findsOneWidget);
    await tester.tap(mapDrawerItem);
    await tester.pumpAndSettle(mapPumpDuration);
    expect(find.byType(MapPage), findsOneWidget);
    await screenshot("map");

    // go to offline maps
    await openDrawer(tester);
    expect(offlineMapsDrawerItem, findsOneWidget);
    await tester.tap(offlineMapsDrawerItem);
    await tester.pumpAndSettle(mapPumpDuration);
    expect(find.byType(OfflineMapsPage), findsOneWidget);
    await screenshot("offline_maps");

    // go to heart rate
    await openDrawer(tester);
    expect(heartRateDrawerItem, findsOneWidget);
    await tester.tap(heartRateDrawerItem);
    await tester.pumpAndSettle();
    expect(find.byType(HeartRatePage), findsOneWidget);
    await screenshot("heart_rate");

    // go to platform_overview
    await openDrawer(tester);
    expect(serverActionsDrawerItem, findsOneWidget);
    await tester.tap(serverActionsDrawerItem);
    await tester.pumpAndSettle();
    expect(find.byType(PlatformOverviewPage), findsOneWidget);
    await screenshot("platform_overview");

    // go to action provider overview TODO
    // go to action rule overview TODO
    // go to action event overview TODO

    // go to settings
    await openDrawer(tester);
    expect(settingsDrawerItem, findsOneWidget);
    await tester.tap(settingsDrawerItem);
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
    await screenshot("settings");

    // go to about
    expect(aboutButton, findsOneWidget);
    await tester.ensureVisible(aboutButton);
    await tester.pumpAndSettle();
    await tester.tap(aboutButton);
    await tester.pumpAndSettle();
    expect(find.byType(AboutPage), findsOneWidget);
    await screenshot("about");
  });
}
