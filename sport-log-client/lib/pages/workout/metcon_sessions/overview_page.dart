import 'package:flutter/material.dart';
import 'package:sport_log/helpers/logger.dart';

class MetconSessionsPage extends StatefulWidget {
  const MetconSessionsPage({Key? key}) : super(key: key);

  @override
  State<MetconSessionsPage> createState() => MetconSessionsPageState();
}

class MetconSessionsPageState extends State<MetconSessionsPage> {
  final _logger = Logger('MetconSessionsPage');

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Not implemented yet :('));
  }

  void onFabTapped(BuildContext context) {
    _logger.d('FAB tapped!');
  }
}
