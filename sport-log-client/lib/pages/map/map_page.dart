import 'package:flutter/material.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/main_drawer.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => MapPageState();
}

class MapPageState extends State<MapPage> {
  final _logger = Logger('MapPage');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Map")),
        drawer: const MainDrawer(selectedRoute: Routes.map),
        body: Text("not implemented"));
  }
}
