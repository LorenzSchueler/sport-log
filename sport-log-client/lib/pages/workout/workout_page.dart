import 'package:flutter/material.dart';
import 'package:sport_log/pages/workout/metcon/metcons_page.dart';
import 'package:sport_log/pages/workout/strength/strength_sessions_page.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/custom_icons.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/wide_screen_frame.dart';

import 'date_filter_state.dart';

enum BottomNavPage { workout, strength, cardio, other }

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  BottomNavPage _currentPage = BottomNavPage.workout;
  final DateFilterState _dateFilter =
      DateFilterState(timeFrame: TimeFrame.month, start: DateTime.now());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        bottom: _timeFilter,
      ),
      body: WideScreenFrame(child: _mainPage),
      bottomNavigationBar: BottomNavigationBar(
        items: BottomNavPage.values.map(_toBottomNavItem).toList(),
        currentIndex: _currentPage.index,
        onTap: _onBottomNavItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
      drawer: const MainDrawer(selectedRoute: Routes.workout),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _onFabTapped(context),
      ),
    );
  }

  Widget get _mainPage {
    switch (_currentPage) {
      case BottomNavPage.workout:
        return const MetconsPage();
      case BottomNavPage.strength:
        return const StrengthSessionsPage();
      case BottomNavPage.cardio:
        return const Center(
          child: Text("Cardio"),
        );
      case BottomNavPage.other:
        return const Center(
          child: Text("Weight and Comments"),
        );
    }
  }

  BottomNavigationBarItem _toBottomNavItem(BottomNavPage page) {
    switch (page) {
      case BottomNavPage.workout:
        return const BottomNavigationBarItem(
          icon: Icon(CustomIcons.plan),
          label: "Workouts",
        );
      case BottomNavPage.strength:
        return const BottomNavigationBarItem(
          icon: Icon(CustomIcons.dumbbellNotRotated),
          label: "Strength",
        );
      case BottomNavPage.cardio:
        return const BottomNavigationBarItem(
          icon: Icon(CustomIcons.heart),
          label: "Cardio",
        );
      case BottomNavPage.other:
        return const BottomNavigationBarItem(
          icon: Icon(Icons.edit),
          label: "Other",
        );
    }
  }

  void _onBottomNavItemTapped(int index) {
    setState(() {
      _currentPage = BottomNavPage.values[index];
    });
  }

  void _onFabTapped(BuildContext context) {
    switch (_currentPage) {
      case BottomNavPage.workout:
        Navigator.of(context).pushNamed(Routes.editMetcon);
        break;
      case BottomNavPage.strength:
        Navigator.of(context).pushNamed(Routes.editStrengthSession);
        break;
      default:
    }
  }

  PreferredSizeWidget get _timeFilter {
    return PreferredSize(
        preferredSize: const Size.fromHeight(30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
                onPressed: _dateFilter.goingForwardPossible
                    ? () => setState(_dateFilter.goForwardInTime)
                    : null,
                icon: const Icon(Icons.arrow_back_ios_sharp)),
            TextButton.icon(
                icon: Text(_dateFilter.getLabel()),
                label: const Icon(Icons.arrow_drop_down_sharp),
                onPressed: () {}),
            IconButton(
                onPressed: () => setState(_dateFilter.goBackInTime),
                icon: const Icon(Icons.arrow_forward_ios_sharp)),
          ],
        ));
  }
}
