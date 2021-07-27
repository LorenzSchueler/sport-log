
import 'package:flutter/material.dart';
import 'package:sport_log/widgets/main_drawer.dart';

class SyncingPage extends StatefulWidget {
  const SyncingPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => SyncingPageState();
}

class SyncingPageState extends State<SyncingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Syncing")),
      body: Center(child: Text("Syncing")),
      drawer: const MainDrawer(),
    );
  }
}