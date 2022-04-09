import 'package:flutter/material.dart' hide Route;
import 'package:sport_log/helpers/extensions/navigator_extension.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';

enum SessionsPageTab { timeline, strength, metcon, cardio, diary }

extension SessionTabUtils on SessionsPageTab {
  int indexOf() {
    return SessionsPageTab.values.indexOf(this);
  }

  String get _entryName {
    switch (this) {
      case SessionsPageTab.timeline:
        return "entries";
      case SessionsPageTab.strength:
        return "strength sessions";
      case SessionsPageTab.metcon:
        return "metcon sessions";
      case SessionsPageTab.cardio:
        return "cardio sessions";
      case SessionsPageTab.diary:
        return "diary entries";
    }
  }

  Widget get noEntriesText => Center(
        child: Text(
          "looks like there are no $_entryName there yet 😔 \nselect a different time range above ↑\nor press ＋ to create a new one",
          textAlign: TextAlign.center,
        ),
      );

  Widget get noEntriesWithoutAddText => Center(
        child: Text(
          "looks like there are no $_entryName there yet 😔 \nselect a different time range above ↑",
          textAlign: TextAlign.center,
        ),
      );

  static void onBottomNavItemTapped(BuildContext context, int index) {
    var sessionRoutes = [
      Routes.timeline.overview,
      Routes.strength.overview,
      Routes.metcon.sessionOverview,
      Routes.cardio.overview,
      Routes.diary.overview,
    ];
    Nav.newBase(context, sessionRoutes[index]);
  }

  static List<BottomNavigationBarItem> get bottomNavItems {
    return SessionsPageTab.values.map(_toBottomNavItem).toList();
  }

  static BottomNavigationBarItem _toBottomNavItem(SessionsPageTab page) {
    switch (page) {
      case SessionsPageTab.timeline:
        return const BottomNavigationBarItem(
          icon: Icon(AppIcons.timeline),
          label: "Timeline",
        );
      case SessionsPageTab.strength:
        return const BottomNavigationBarItem(
          icon: Icon(AppIcons.dumbbell),
          label: "Strength",
        );
      case SessionsPageTab.metcon:
        return const BottomNavigationBarItem(
          icon: Icon(AppIcons.notes),
          label: "Metcon",
        );
      case SessionsPageTab.cardio:
        return const BottomNavigationBarItem(
          icon: Icon(AppIcons.heartbeat),
          label: "Cardio",
        );
      case SessionsPageTab.diary:
        return const BottomNavigationBarItem(
          icon: Icon(AppIcons.calendar),
          label: "Diary",
        );
    }
  }

  static BottomNavigationBar bottomNavigationBar(
    BuildContext context,
    SessionsPageTab sessionsPageTab,
  ) {
    return BottomNavigationBar(
      items: SessionTabUtils.bottomNavItems,
      currentIndex: sessionsPageTab.indexOf(),
      onTap: (index) => SessionTabUtils.onBottomNavItemTapped(context, index),
      type: BottomNavigationBarType.fixed,
    );
  }
}
