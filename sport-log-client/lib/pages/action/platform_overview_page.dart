import 'package:flutter/material.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/main_drawer.dart';

class PlatformOverviewPage extends StatefulWidget {
  const PlatformOverviewPage({Key? key}) : super(key: key);

  @override
  State<PlatformOverviewPage> createState() => PlatformOverviewPageState();
}

class PlatformOverviewPageState extends State<PlatformOverviewPage> {
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
      drawer: MainDrawer(selectedRoute: Routes.action.platformOverview),
    );
  }
}
