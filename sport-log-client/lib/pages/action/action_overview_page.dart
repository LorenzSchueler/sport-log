import 'package:flutter/material.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/main_drawer.dart';

class ActionOverviewPage extends StatefulWidget {
  const ActionOverviewPage({Key? key}) : super(key: key);

  @override
  State<ActionOverviewPage> createState() => ActionOverviewPageState();
}

class ActionOverviewPageState extends State<ActionOverviewPage> {
  final _logger = Logger('ActionOverviewPage');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Server Actions"),
      ),
      body: Container(
        padding: Defaults.edgeInsets.normal,
        child: ListView(
          children: const [Text("not implemented")],
        ),
      ),
      drawer: MainDrawer(selectedRoute: Routes.action.overview),
    );
  }
}
