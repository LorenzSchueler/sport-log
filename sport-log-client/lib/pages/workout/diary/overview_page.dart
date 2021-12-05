import 'package:flutter/material.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/routes.dart';

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

  Widget? fab(BuildContext context) {
    _logger.d('FAB called!');

    return FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.of(context).pushNamed(Routes.diary.edit);
        });
  }
}
