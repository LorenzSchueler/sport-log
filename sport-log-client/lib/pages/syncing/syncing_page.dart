
import 'package:flutter/material.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/main_drawer.dart';

class SyncingPage extends StatefulWidget {
  const SyncingPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SyncingPageState();
}

class _SyncingPageState extends State<SyncingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Syncing")),
      body: const Center(child: Text("Syncing")),
      drawer: const MainDrawer(selectedRoute: Routes.syncing),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {

        },
      ),
    );
  }
}