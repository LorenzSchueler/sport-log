
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_log/authentication/authentication_bloc.dart';
import 'package:sport_log/routes.dart';

enum BottomNavPage {
  syncing, logging
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {

  BottomNavPage _currentPage = BottomNavPage.syncing;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        actions: [
          IconButton(
            onPressed: () {
              context.read<AuthenticationBloc>().add(const LogoutEvent());
              Navigator.pushNamedAndRemoveUntil(
                  context, Routes.landing, (route) => false);
            },
            icon: const Icon(
                Icons.logout
            ),
          ),
        ],
      ),
      body: _mainPage,
      bottomNavigationBar: BottomNavigationBar(
        items: BottomNavPage.values.map(_toBottomNavItem).toList(),
        currentIndex: _currentPage.index,
        onTap: _onBottomNavItemTapped,
      ),
    );
  }

  Widget get _mainPage {
    switch (_currentPage) {
      case BottomNavPage.syncing:
        return const Center(
          child: Text("Syncing"),
        );
      case BottomNavPage.logging:
        return const Center(
          child: Text("Logging"),
        );
    }
  }

  BottomNavigationBarItem _toBottomNavItem(BottomNavPage page) {
    switch (page) {
      case BottomNavPage.syncing:
        return const BottomNavigationBarItem(
          icon: Icon(Icons.sync),
          label: "Sync",
        );
      case BottomNavPage.logging:
        return const BottomNavigationBarItem(
            icon: Icon(Icons.edit),
          label: "Logs",
        );
    }
  }

  void _onBottomNavItemTapped(int index) {
    setState(() {
      _currentPage = BottomNavPage.values[index];
    });
  }
}