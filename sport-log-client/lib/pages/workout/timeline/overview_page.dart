import 'package:flutter/material.dart';
import 'package:sport_log/helpers/logger.dart';

class TimelinePage extends StatefulWidget {
  const TimelinePage({Key? key}) : super(key: key);

  @override
  State<TimelinePage> createState() => TimelinePageState();
}

class TimelinePageState extends State<TimelinePage> {
  final _logger = Logger('TimelinePage');

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Not implemented yet :('));
  }

  Widget? fab(BuildContext context) {
    _logger.d('FAB called!');

    return null;
  }
}
