import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/strength_data_provider.dart';
import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/strength/all.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/pages/workout/strength_sessions/charts/helpers.dart';
import 'package:sport_log/pages/workout/strength_sessions/charts/series_type.dart';

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
  final _dataProvider = StrengthSessionDescriptionDataProvider();

  List<StrengthSessionStats> _strengthSessionStats = [];

  @override
  void initState() {
    super.initState();
    _dataProvider.addListener(_update);
    _update();
  }

  Future<void> _update() async {
    final strengthSessionStats = await _dataProvider.getStatsAggregationsByDay(
      movementId: widget.movement.id,
      from: widget.start,
      until: widget.start.monthLater(),
    );
    assert(strengthSessionStats.length <= 31);
    if (mounted) {
      setState(() => _strengthSessionStats = strengthSessionStats);
    }
  }

  @override
  void didUpdateWidget(MonthChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ignore a change in series type
    if (oldWidget.movement != widget.movement ||
        oldWidget.start != widget.start) {
      _update();
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
            spots: _strengthSessionStats.map((s) {
              return FlSpot(s.datetime.day.toDouble(), getValue(s));
            }).toList(),
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
        titlesData: FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 2,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: isTime ? 60 : 40,
              getTitlesWidget: isTime
                  ? (value, _) => Text(
                        Duration(milliseconds: value.round())
                            .formatTimeWithMillis,
                      )
                  : null,
            ),
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
    _dataProvider.removeListener(_update);
    super.dispose();
  }
}
