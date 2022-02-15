import 'package:flutter/material.dart';
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
          padding: const EdgeInsets.all(10),
          child: ListView(
            children: [const Text("data")],
          )),
      drawer: MainDrawer(selectedRoute: Routes.action.overview),
    );
  }
}
