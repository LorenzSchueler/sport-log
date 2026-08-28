import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart'
    show
        MapWidget,
        MapboxMap,
        RenderedQueryGeometry,
        RenderedQueryOptions,
        ScreenBox,
        ScreenCoordinate;
import 'package:material_ui/material_ui.dart';
import 'package:sport_log/data_provider/sync.dart';
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
import 'package:sport_log/pages/workout/metcon_sessions/metcon_session_results_card.dart';
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

const serverUrl = "http://10.0.2.2:8001";
const username = "ScreenshotUser";
const password = "ScreenshotPassword0";

/// `screenshots.sh` watches for capture markers.
const screenshotDir = '/storage/emulated/0/Download';

const pollInterval = Duration(milliseconds: 100);
const waitTimeout = Duration(seconds: 60);

const mapSettleChecks = 5;

Finder input(String text) =>
    find.ancestor(of: find.text(text), matching: find.byType(TextFormField));
final serverUrlInput = input("Server URL");
final usernameInput = input("Username");
final passwordInput = input("Password");

Finder button(String text) =>
    find.ancestor(of: find.text(text), matching: find.byType(FilledButton));
final loginButton = button("Login");
final registerButton = button("Register");
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
final metconButton = iconButton(AppIcons.notes);
final editButton = iconButton(AppIcons.edit);
final cutButton = iconButton(AppIcons.cut);
final elevationButton = iconButton(AppIcons.trendingUp);

final discardChanges = find.ancestor(
  of: find.text("Discard Changes"),
  matching: find.byType(TextButton),
);

Finder strengthSessionCard(String movement) => find
    .ancestor(
      of: find.text(movement),
      matching: find.byType(StrengthSessionCard),
    )
    .first;

final metconScores = find.descendant(
  of: find.descendant(
    of: find.byType(MetconSessionResultsCard),
    matching: find.byType(Table),
  ),
  matching: find.byType(Text),
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

/// Pumps frames until [condition] is met.
///
/// Unlike [WidgetTester.pumpAndSettle] this also waits for work that does not
/// schedule frames, like database queries, http requests and map rendering.
Future<void> waitUntil(
  WidgetTester tester,
  String description,
  FutureOr<bool> Function() condition,
) async {
  final stopwatch = Stopwatch()..start();
  while (!await condition()) {
    if (stopwatch.elapsed > waitTimeout) {
      throw TimeoutException("waiting for $description", waitTimeout);
    }
    await tester.pump(pollInterval);
  }
  await tester.pumpAndSettle();
}

Future<void> waitFor(WidgetTester tester, Finder finder) =>
    waitUntil(tester, finder.describeMatch(Plurality.one), () {
      try {
        return finder.tryEvaluate();
      } on StateError {
        return false; // `first` finders throw while there is no match
      }
    });

/// The controllers of all maps of the current page.
Iterable<MapboxMap> mapControllers(WidgetTester tester) => tester
    .stateList<State<StatefulWidget>>(find.byType(MapWidget))
    .map((state) => (state as dynamic).mapboxMap as MapboxMap?)
    .nonNulls;

/// Describes what [map] currently shows.
///
/// Null while the style is still loading.
Future<String?> mapContent(MapboxMap map) async {
  if (!await map.style.isStyleLoaded()) {
    return null;
  }
  final camera = await map.getCameraState();
  final size = await map.getSize();
  final features = await map.queryRenderedFeatures(
    RenderedQueryGeometry.fromScreenBox(
      ScreenBox(
        min: ScreenCoordinate(x: 0, y: 0),
        max: ScreenCoordinate(x: size.width, y: size.height),
      ),
    ),
    RenderedQueryOptions(),
  );
  return "${camera.center.coordinates} ${camera.zoom} ${camera.bearing} "
      "${camera.pitch} ${features.length}";
}

/// Waits until all maps of the current page have rendered all their tiles.
///
/// A map is done once its camera and its rendered features stayed the same for
/// [mapSettleChecks] checks. Waiting for the camera to come to rest also keeps
/// the position which is stored as `lastMapPosition` reproducible.
Future<void> waitMapRender(WidgetTester tester) async {
  var previous = <String?>[];
  var unchanged = 0;
  await waitUntil(tester, "maps to render", () async {
    final current = [
      for (final map in mapControllers(tester)) await mapContent(map),
    ];
    unchanged = current.contains(null) || !listEquals(current, previous)
        ? 0
        : unchanged + 1;
    previous = current;
    return unchanged >= mapSettleChecks;
  });
}

Future<void> tap(
  WidgetTester tester,
  Finder finder, {
  bool warnIfMissed = true,
}) async {
  await waitFor(tester, finder);
  await tester.tap(finder, warnIfMissed: warnIfMissed);
  await tester.pumpAndSettle();
}

/// Long pressing an overview card filters the overview by its movement/metcon.
Future<void> longPress(WidgetTester tester, Finder finder) async {
  await waitFor(tester, finder);
  await tester.longPress(finder);
  await tester.pumpAndSettle();
}

Future<void> enterText(WidgetTester tester, Finder finder, String text) async {
  await waitFor(tester, finder);
  await tester.enterText(finder, text);
  await tester.pumpAndSettle();
}

/// Requests a screenshot from `screenshots.sh` and waits until it was taken.
///
/// The screenshot is not taken here because the integration test can only
/// capture the flutter surface which contains neither the system bars nor the
/// platform views of the maps.
Future<void> screenshot(WidgetTester tester, String filename) async {
  // a blinking text cursor would make the screenshot non reproducible
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();

  final marker = File("$screenshotDir/$filename.capture");
  await marker.writeAsString("", flush: true);
  await waitUntil(tester, "screenshot $filename", () => !marker.existsSync());
  logger.i("$screenshotDir/$filename.png");
}

// ignore: long-method
void main() {
  testWidgets('screenshots', (tester) async {
    // do not use app.main() to avoid GlobalErrorHandler
    runApp(const InitAppWrapper());

    // landing
    await waitFor(tester, find.byType(LandingPage));
    await screenshot(tester, "landing");

    // go to register
    await tap(tester, registerButton);
    expect(find.byType(LoginPage), findsOneWidget);
    await screenshot(tester, "register");
    await tap(tester, backButton); // back to landing

    // go to login
    await tap(tester, loginButton);
    expect(find.byType(LoginPage), findsOneWidget);
    await screenshot(tester, "login");

    // login and go to timeline
    await enterText(tester, serverUrlInput, serverUrl);
    await enterText(tester, usernameInput, username);
    await enterText(tester, passwordInput, password);
    await tap(tester, loginButton);
    await waitFor(tester, find.byType(TimelinePage));
    // a sync during the run would change the last sync time and spin the sync
    // icon in the drawer
    await waitUntil(tester, "sync", () => !Sync.instance.isSyncing);
    Sync.instance.stopSync();
    await waitMapRender(tester);
    await screenshot(tester, "timeline");

    // go to strength overview
    await tap(tester, strengthNavItem);
    expect(find.byType(StrengthOverviewPage), findsOneWidget);
    await waitFor(tester, find.byType(StrengthSessionCard));
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

    // filter strength overview by movement to show chart and records
    await longPress(tester, strengthSessionCard("Back Squat"));
    await screenshot(tester, "strength_overview_filtered");

    // go to metcon session overview
    await tap(tester, metconNavItem);
    expect(find.byType(MetconSessionOverviewPage), findsOneWidget);
    await waitFor(tester, find.byType(MetconSessionCard));
    await screenshot(tester, "metcon_session_overview");

    // go to metcon session details
    await tap(tester, find.byType(MetconSessionCard).first);
    expect(find.byType(MetconSessionDetailsPage), findsOneWidget);
    await waitFor(tester, metconScores);
    await screenshot(tester, "metcon_session_details");

    // go to metcon session edit
    await tap(tester, editButton);
    expect(find.byType(MetconSessionEditPage), findsOneWidget);
    await screenshot(tester, "metcon_session_edit");
    await backDiscardChanges(tester); // back to details
    await tap(tester, backButton); // back to overview

    // filter metcon session overview by metcon to show metcon and results
    await longPress(tester, find.byType(MetconSessionCard).first);
    await screenshot(tester, "metcon_session_overview_filtered");

    // go to metcon overview
    await tap(tester, metconButton);
    expect(find.byType(MetconOverviewPage), findsOneWidget);
    await waitFor(tester, find.byType(MetconCard));
    await screenshot(tester, "metcon_overview");

    // go to metcon details
    await tap(tester, find.byType(MetconCard).first);
    expect(find.byType(MetconDetailsPage), findsOneWidget);
    await screenshot(tester, "metcon_details");
    await tap(tester, backButton); // back to metcon overview

    // go to metcon edit
    await tap(tester, addFab);
    expect(find.byType(MetconEditPage), findsOneWidget);
    await screenshot(tester, "metcon_edit");
    await backDiscardChanges(tester);

    // go to cardio overview
    await tap(tester, cardioNavItem);
    expect(find.byType(CardioOverviewPage), findsOneWidget);
    await waitFor(tester, find.byType(CardioSessionCard));
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

    // filter cardio overview by movement to show chart
    await longPress(tester, find.textContaining(" at ").first);
    await waitMapRender(tester);
    await screenshot(tester, "cardio_overview_filtered");

    // go to tracking settings
    await tap(tester, addFab);
    await tap(tester, stopwatchFab);
    expect(find.byType(CardioTrackingSettingsPage), findsOneWidget);
    await screenshot(tester, "tracking_settings");

    // go to tracking
    await tap(tester, okButton);
    expect(find.byType(CardioTrackingPage), findsOneWidget);
    await waitFor(tester, cancelButton); // wait for permission requests
    await waitMapRender(tester);
    await screenshot(tester, "tracking");
    await tap(tester, cancelButton); // back to tracking settings
    await tap(tester, backButton); // back to cardio overview

    // go to route overview
    await tap(tester, routeButton);
    expect(find.byType(RouteOverviewPage), findsOneWidget);
    await waitFor(tester, find.byType(RouteCard));
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
    await waitFor(tester, find.byType(WodCard));
    await screenshot(tester, "wod_overview");

    // go to wod session edit
    await tap(tester, find.byType(WodCard).first);
    expect(find.byType(WodEditPage), findsOneWidget);
    await screenshot(tester, "wod_edit");
    await backDiscardChanges(tester);

    // go to diary overview
    await tap(tester, diaryNavItem);
    expect(find.byType(DiaryOverviewPage), findsOneWidget);
    await waitFor(tester, find.byType(DiaryCard));
    await screenshot(tester, "diary_overview");

    // go to diary session edit
    await tap(tester, find.byType(DiaryCard).first);
    expect(find.byType(DiaryEditPage), findsOneWidget);
    await screenshot(tester, "diary_edit");
    await backDiscardChanges(tester);

    // open drawer
    await openDrawer(tester);
    await screenshot(tester, "drawer");

    // go to movement overview
    await tap(tester, movementDrawerItem);
    expect(find.byType(MovementOverviewPage), findsOneWidget);
    await waitFor(tester, find.byType(MovementCard));
    await screenshot(tester, "movement_overview");

    // go to movement edit
    await tap(tester, addFab);
    expect(find.byType(MovementEditPage), findsOneWidget);
    await screenshot(tester, "movement_edit");
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

    // show map styles
    await tap(tester, layersFab);
    await waitMapRender(tester);
    await screenshot(tester, "map_styles");

    // switch to satellite style
    await tap(tester, find.byIcon(AppIcons.satellite));
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
    await waitFor(tester, find.text("wodify-login"));
    await screenshot(tester, "platform_overview");

    // go to action provider overview
    await tap(tester, find.text("wodify-login"));
    expect(find.byType(ActionProviderOverviewPage), findsOneWidget);
    await waitFor(tester, find.byType(ActionEventsCard));
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
    await waitFor(tester, aboutButton);
    await tester.ensureVisible(aboutButton);
    await tester.pumpAndSettle();
    await tap(tester, aboutButton);
    expect(find.byType(AboutPage), findsOneWidget);
    await screenshot(tester, "about");
  });
}
