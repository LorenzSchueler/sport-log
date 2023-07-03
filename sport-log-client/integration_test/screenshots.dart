import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/main.dart';
import 'package:sport_log/pages/login/landing_page.dart';
import 'package:sport_log/pages/login/login_page.dart';
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

final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

const serverUrl = "http://10.0.2.2:8001";
const username = "uq";
const password = "123456aBC";

final serverUrlInput = find.ancestor(
  of: find.text("Server URL"),
  matching: find.byType(TextFormField),
);

final usernameInput = find.ancestor(
  of: find.text("Username"),
  matching: find.byType(TextFormField),
);

final passwordInput = find.ancestor(
  of: find.text("Password"),
  matching: find.byType(TextFormField),
);

final loginButton = find.ancestor(
  of: find.text("Login"),
  matching: find.byType(ElevatedButton),
);

final plusFab = find.ancestor(
  of: find.byIcon(AppIcons.add),
  matching: find.byType(FloatingActionButton),
);

final editFab = find.ancestor(
  of: find.byIcon(AppIcons.notes),
  matching: find.byType(FloatingActionButton),
);

final routeFab = find.ancestor(
  of: find.byIcon(AppIcons.route),
  matching: find.byType(FloatingActionButton),
);

final backButton = find.byType(BackButton);

final discardChanges = find.ancestor(
  of: find.text("Discard Changes"),
  matching: find.byType(TextButton),
);

final strengthNavItem = find.ancestor(
  of: find.text("Strength"),
  matching: find.byWidgetPredicate(
    (widget) => widget.runtimeType.toString() == "_BottomNavigationTile",
  ),
);

final metconNavItem = find.ancestor(
  of: find.text("Metcon"),
  matching: find.byWidgetPredicate(
    (widget) => widget.runtimeType.toString() == "_BottomNavigationTile",
  ),
);

final cardioNavItem = find.ancestor(
  of: find.text("Cardio"),
  matching: find.byWidgetPredicate(
    (widget) => widget.runtimeType.toString() == "_BottomNavigationTile",
  ),
);

final diaryNavItem = find.ancestor(
  of: find.text("Diary"),
  matching: find.byWidgetPredicate(
    (widget) => widget.runtimeType.toString() == "_BottomNavigationTile",
  ),
);

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

    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.byType(LandingPage), findsOneWidget);
    await screenshot("landing");

    // choose login option
    expect(loginButton, findsOneWidget);
    await tester.tap(loginButton);
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    await screenshot("login");

    // fill login form and login
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

    // go to strength session overview
    expect(strengthNavItem, findsOneWidget);
    await tester.tap(strengthNavItem);
    await tester.pumpAndSettle();
    expect(find.byType(StrengthOverviewPage), findsOneWidget);
    await screenshot("strength_session_overview");

    // go to strength session edit
    expect(plusFab, findsOneWidget);
    await tester.tap(plusFab);
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

    // go to metcon session edit
    expect(plusFab, findsOneWidget);
    await tester.tap(plusFab);
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

    // go to metcon edit
    expect(plusFab, findsOneWidget);
    await tester.tap(plusFab);
    await tester.pumpAndSettle();
    expect(find.byType(MetconEditPage), findsOneWidget);
    await screenshot("metcon_edit");
    await backDiscardChanges(tester);

    // go to cardio session overview
    expect(cardioNavItem, findsOneWidget);
    await tester.tap(cardioNavItem);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.byType(CardioOverviewPage), findsOneWidget);
    await screenshot("cardio_session_overview");

    // go to cardio session edit
    expect(plusFab, findsOneWidget);
    await tester.tap(plusFab);
    await tester.pumpAndSettle();
    expect(editFab, findsOneWidget);
    await tester.tap(editFab);
    await tester.pumpAndSettle();
    expect(find.byType(CardioEditPage), findsOneWidget);
    await screenshot("cardio_session_edit");
    await backDiscardChanges(tester);

    // go to route overview
    final routeButton = find.ancestor(
      of: find.byIcon(AppIcons.route),
      matching: find.byType(IconButton),
    );
    expect(routeButton, findsOneWidget);
    await tester.tap(routeButton);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.byType(RouteOverviewPage), findsOneWidget);
    await screenshot("route_overview");

    // go to route edit
    expect(plusFab, findsOneWidget);
    await tester.tap(plusFab);
    await tester.pumpAndSettle();
    expect(routeFab, findsOneWidget);
    await tester.tap(routeFab);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.byType(RouteEditPage), findsOneWidget);
    await screenshot("route_edit");
    await backDiscardChanges(tester);

    // go to diary overview
    expect(diaryNavItem, findsOneWidget);
    await tester.tap(diaryNavItem);
    await tester.pumpAndSettle();
    expect(find.byType(DiaryOverviewPage), findsOneWidget);
    await screenshot("diary_overview");

    // go to strength session edit
    expect(plusFab, findsOneWidget);
    await tester.tap(plusFab);
    await tester.pumpAndSettle();
    await screenshot("diary_edit");
    expect(find.byType(DiaryEditPage), findsOneWidget);
    await backDiscardChanges(tester);
  });
}
