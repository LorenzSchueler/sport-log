
import 'package:flutter/material.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/main_drawer.dart';

class MovementsPage extends StatelessWidget {
  const MovementsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Movements"),),
      body: const Center(child: Text("Movements")),
      drawer: const MainDrawer(selectedRoute: Routes.movements),
    );
  }
}