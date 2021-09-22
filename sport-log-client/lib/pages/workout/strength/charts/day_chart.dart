import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/strength_data_provider.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/strength/all.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';

import 'series_type.dart';

/// needs to wrapped into something that constrains the size (e. g. an [AspectRatio])
class DayChart extends StatefulWidget {
  DayChart({
    Key? key,
    required this.series,
    required DateTime date,
    required this.movement,
  })  : date = date.beginningOfDay(),
        super(key: key);

  final SeriesType series;
  final DateTime date;
  final Movement movement;

  @override
  State<DayChart> createState() => _DayChartState();
}

class _DayChartState extends State<DayChart> {
  final _dataProvider = StrengthDataProvider();

  List<StrengthSessionDescription> _sessions = [];

  @override
  void initState() {
    super.initState();
    update();
  }

  void update() {
    _dataProvider
        .getSessionsWithStats(
      movementId: widget.movement.id,
      from: widget.date,
      until: widget.date.dayLater(),
      withSets: true,
    )
        .then((sessions) {
      setState(() {
        _sessions = sessions;
      });
    });
  }

  @override
  void didUpdateWidget(DayChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ignore a change in series type
    if (oldWidget.movement != widget.movement ||
        oldWidget.date != widget.date) {
      update();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sessions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return Container();
  }
}
