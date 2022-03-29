import 'package:flutter/material.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/main_drawer.dart';

class ActionOverviewPage extends StatefulWidget {
  const ActionOverviewPage({Key? key}) : super(key: key);

  @override
  State<ActionOverviewPage> createState() => _ActionOverviewPageState();
}

class _ActionOverviewPageState extends State<ActionOverviewPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Actions"),
      ),
      body: Container(
        padding: Defaults.edgeInsets.normal,
        child: ListView(
          children: const [
            Text("not implemented"),
          ],
        ),
      ),
      drawer: MainDrawer(selectedRoute: Routes.action.actionOverview),
    );
  }
}
