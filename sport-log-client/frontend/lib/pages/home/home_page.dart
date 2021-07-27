
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_log/authentication/authentication_bloc.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/custom_icons.dart';
import 'package:sport_log/helpers/navigator_extension.dart';
import 'package:sport_log/widgets/main_drawer.dart';

enum BottomNavPage {
  workout, strength, cardio
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {

  BottomNavPage _currentPage = BottomNavPage.workout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
      ),
      body: _mainPage,
      bottomNavigationBar: BottomNavigationBar(
        items: BottomNavPage.values.map(_toBottomNavItem).toList(),
        currentIndex: _currentPage.index,
        onTap: _onBottomNavItemTapped,
      ),
      drawer: const MainDrawer(),
    );
  }

  Widget get _mainPage {
    switch (_currentPage) {
      case BottomNavPage.workout:
        return const Center(
          child: Text("Workouts/Metcon"),
        );
      case BottomNavPage.strength:
        return const Center(
          child: Text("Strength"),
        );
      case BottomNavPage.cardio:
        return const Center(
          child: Text("Cardio"),
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
    }
  }

  void _onBottomNavItemTapped(int index) {
    setState(() {
      _currentPage = BottomNavPage.values[index];
    });
  }
}