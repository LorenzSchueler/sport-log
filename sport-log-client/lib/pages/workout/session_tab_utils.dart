import 'package:flutter/material.dart' hide Route;
import 'package:sport_log/helpers/extensions/navigator_extension.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';

enum SessionsPageTab {
  timeline(Routes.timelineOverview, AppIcons.timeline, "Timeline", "entries"),
  strength(
    Routes.strengthOverview,
    AppIcons.dumbbell,
    "Strength",
    "strength sessions",
  ),
  metcon(
    Routes.metconSessionOverview,
    AppIcons.notes,
    "Metcon",
    "metcon sessions",
  ),
  cardio(
    Routes.cardioOverview,
    AppIcons.heartbeat,
    "Cardio",
    "cardio sessions",
  ),
  wod(Routes.wodOverview, AppIcons.sports, "Wod", "wods"),
  diary(Routes.diaryOverview, AppIcons.calendar, "Diary", "diary entries");

  const SessionsPageTab(this.route, this.icon, this.label, this.entryName);
  final String route;
  final IconData icon;
  final String label;
  final String entryName;

  String get noEntriesText =>
      "Looks like there are no $entryName there yet 😔 \nSelect a different time range above ↑\nor press ＋ to create a new one";

  String get noEntriesWithoutAddText =>
      "Looks like there are no $entryName there yet 😔 \nSelect a different time range above ↑";

  static NavigationBar bottomNavigationBar({
    required BuildContext context,
    required SessionsPageTab sessionsPageTab,
  }) {
    return NavigationBar(
      destinations: SessionsPageTab.values
          .map(
            (tab) =>
                NavigationDestination(icon: Icon(tab.icon), label: tab.label),
          )
          .toList(),
      selectedIndex: sessionsPageTab.index,
      onDestinationSelected: (index) =>
          Navigator.of(context).newBase(values[index].route),
    );
  }
}
