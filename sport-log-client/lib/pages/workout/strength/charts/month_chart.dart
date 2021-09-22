import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/strength_data_provider.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/strength/all.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';

import 'series_type.dart';

/// needs to wrapped into something that constrains the size (e. g. an [AspectRatio])
class MonthChart extends StatefulWidget {
  MonthChart({
    Key? key,
    required this.series,
    required DateTime start,
    required this.movement,
  })  : start = start.beginningOfMonth(),
        super(key: key);

  final SeriesType series;
  final DateTime start;
  final Movement movement;

  @override
  State<MonthChart> createState() => _MonthChartState();
}

class _MonthChartState extends State<MonthChart> {
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
      movementId: widget.movement.id,
      from: widget.start,
      until: widget.start.monthLater(),
    )
        .then((stats) {
      assert(stats.length <= 31);
      if (mounted) {
        setState(() {
          _stats = stats;
        });
      }
    });
  }

  @override
  void didUpdateWidget(MonthChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ignore a change in series type
    if (oldWidget.movement != widget.movement ||
        oldWidget.start != widget.start) {
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
