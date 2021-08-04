
import 'package:flutter/material.dart';
import 'package:sport_log/pages/workout/metcon/metcons_page.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/custom_icons.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/wide_screen_frame.dart';

enum BottomNavPage {
  workout, strength, cardio, other
}

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {

  BottomNavPage _currentPage = BottomNavPage.workout;
  bool get _showFab => _currentPage == BottomNavPage.workout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
      ),
      body: WideScreenFrame(child: _mainPage),
      bottomNavigationBar: BottomNavigationBar(
        items: BottomNavPage.values.map(_toBottomNavItem).toList(),
        currentIndex: _currentPage.index,
        onTap: _onBottomNavItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
      drawer: const MainDrawer(selectedRoute: Routes.workout),
      floatingActionButton: _showFab ? FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _onFabTapped(context),
      ) : null,
    );
  }

  Widget get _mainPage {
    switch (_currentPage) {
      case BottomNavPage.workout:
        return const MetconsPage();
      case BottomNavPage.strength:
        return const Center(
          child: Text("Strength"),
        );
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
          icon: Icon(CustomIcons.dumbbell_not_rotated),
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
      default:
    }
  }
}