
import 'package:flutter/material.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/main_drawer.dart';

class LogsPage extends StatelessWidget {
  const LogsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Logs")),
      body: const Center(child: Text("Logs by day")),
      drawer: const MainDrawer(selectedRoute: Routes.logs),
    );
  }
}