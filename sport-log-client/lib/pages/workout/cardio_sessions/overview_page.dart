import 'package:flutter/material.dart';
import 'package:sport_log/helpers/logger.dart';

class CardioSessionsPage extends StatefulWidget {
  const CardioSessionsPage({Key? key}) : super(key: key);

  @override
  State<CardioSessionsPage> createState() => CardioSessionsPageState();
}

class CardioSessionsPageState extends State<CardioSessionsPage> {
  final _logger = Logger('CardioSessionsPage');

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Not implemented yet :('));
  }

  void onFabTapped(BuildContext context) {
    _logger.d('FAB tapped!');
  }
}
