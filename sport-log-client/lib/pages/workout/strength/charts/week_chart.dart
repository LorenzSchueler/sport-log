import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/strength_data_provider.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/strength/all.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';

import 'series_type.dart';

/// needs to wrapped into something that constrains the size (e. g. an [AspectRatio])
class WeekChart extends StatefulWidget {
  WeekChart({
    Key? key,
    required this.series,
    required this.unit,
    required DateTime start,
    required this.movementId,
  }) : start = start.beginningOfWeek(), super(key: key);

  final SeriesType series;
  final MovementUnit unit;
  final DateTime start;
  final Int64 movementId;

  @override
  State<WeekChart> createState() => _WeekChartState();
}

class _WeekChartState extends State<WeekChart> {
  final _dataProvider = StrengthDataProvider();

  List<StrengthSessionStats> _stats = [];

  @override
  void initState() {
    super.initState();
    update();
  }

  void update() {
    _dataProvider
        .getStatsByDay(
      movementId: widget.movementId,
      from: widget.start,
      until: widget.start.weekLater(),
    )
        .then((stats) {
      assert(stats.length <= 7);
      setState(() {
        _stats = stats;
      });
    });
  }

  @override
  void didUpdateWidget(WeekChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ignore a change in series type
    if (oldWidget.unit != widget.unit ||
        oldWidget.start != widget.start ||
        oldWidget.movementId != widget.movementId) {
      update();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_stats.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return Container();
  }
}
