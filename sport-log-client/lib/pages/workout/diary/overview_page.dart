import 'package:flutter/material.dart';
import 'package:sport_log/helpers/logger.dart';

class DiaryPage extends StatefulWidget {
  const DiaryPage({Key? key}) : super(key: key);

  @override
  State<DiaryPage> createState() => DiaryPageState();
}

class DiaryPageState extends State<DiaryPage> {
  final _logger = Logger('DiaryPage');

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Not implemented yet :('));
  }

  void onFabTapped() {
    _logger.d('FAB tapped!');
  }
}
