import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/strength_data_provider.dart';
import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/helpers/theme.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/strength/all.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/pages/workout/strength_sessions/charts/helpers.dart';

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
  final _dataProvider = StrengthDataProvider.instance;

  List<StrengthSessionStats> _stats = [];

  @override
  void initState() {
    super.initState();
    _dataProvider.addListener(update);
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
        setState(() => _stats = stats);
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
    final getValue = statsAccessor(widget.series);
    final isTime = widget.movement.dimension == MovementDimension.time;
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: _stats.map((s) {
              return FlSpot(s.datetime.day.toDouble(), getValue(s));
            }).toList(),
            colors: [primaryColorOf(context)],
          ),
        ],
        titlesData: FlTitlesData(
          topTitles: SideTitles(showTitles: false),
          rightTitles: SideTitles(showTitles: false),
          bottomTitles: SideTitles(
            showTitles: true,
            interval: 2,
          ),
          leftTitles: SideTitles(
            showTitles: true,
            reservedSize: isTime ? 60 : 40,
            getTitles: isTime
                ? (value) =>
                    formatDurationShort(Duration(milliseconds: value.round()))
                : null,
          ),
        ),
        gridData: FlGridData(
          verticalInterval: 2,
          getDrawingHorizontalLine: gridLineDrawer(context),
          getDrawingVerticalLine: gridLineDrawer(context),
        ),
        minX: 1.0,
        maxX: widget.start.numDaysInMonth.toDouble(),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  @override
  void dispose() {
    _dataProvider.removeListener(update);
    super.dispose();
  }
}
