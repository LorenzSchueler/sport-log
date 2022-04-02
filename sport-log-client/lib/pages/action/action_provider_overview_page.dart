import 'package:flutter/material.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/main_drawer.dart';

class ActionProviderOverviewPage extends StatefulWidget {
  final ActionProvider actionProvider;

  const ActionProviderOverviewPage({required this.actionProvider, Key? key})
      : super(key: key);

  @override
  State<ActionProviderOverviewPage> createState() =>
      _ActionProviderOverviewPageState();
}

class _ActionProviderOverviewPageState
    extends State<ActionProviderOverviewPage> {
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
      drawer: MainDrawer(selectedRoute: Routes.action.actionProviderOverview),
    );
  }
}
