
import 'package:flutter/material.dart';

class SyncingPage extends StatefulWidget {
  const SyncingPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => SyncingPageState();
}

class SyncingPageState extends State<SyncingPage> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Syncing")
    );
  }
}