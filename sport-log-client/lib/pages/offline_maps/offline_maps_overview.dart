import 'package:flutter/material.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/main_drawer.dart';

class OfflineMapsPage extends StatefulWidget {
  const OfflineMapsPage({Key? key}) : super(key: key);

  @override
  State<OfflineMapsPage> createState() => OfflineMapsPageState();
}

class OfflineMapsPageState extends State<OfflineMapsPage> {
  final _logger = Logger('OfflineMapsPage');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Offline Maps")),
        drawer: const MainDrawer(selectedRoute: Routes.offlineMaps),
        body: Text("not implemented"));
  }
}
