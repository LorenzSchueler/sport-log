import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/strength_data_provider.dart';
import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/helpers/theme.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/strength/all.dart';
import 'package:sport_log/pages/workout/strength_sessions/charts/helpers.dart';
import 'package:sport_log/pages/workout/strength_sessions/charts/series_type.dart';

/// needs to wrapped into something that constrains the size (e. g. an [AspectRatio])
class AllChart extends StatefulWidget {
  const AllChart({
    Key? key,
    required this.series,
    required this.movement,
  }) : super(key: key);

  final SeriesType series;
  final Movement movement;

  @override
  State<AllChart> createState() => _AllChartState();
}

class _AllChartState extends State<AllChart> {
  final _dataProvider = StrengthSessionDescriptionDataProvider.instance;

  List<StrengthSessionStats> _strengthSessionStats = [];

  @override
  void initState() {
    super.initState();
    _dataProvider.addListener(_update);
    _update();
  }

  Future<void> _update() async {
    final strengthSessionStats = await _dataProvider
        .getStatsAggregationsByMonth(movementId: widget.movement.id);
    if (mounted) {
      setState(() => _strengthSessionStats = strengthSessionStats);
    }
  }

  @override
  void didUpdateWidget(AllChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ignore a change in series type
    if (oldWidget.movement != widget.movement) {
      _update();
    }
  }

  @override
  Widget build(BuildContext context) {
    final getValue = statsAccessor(widget.series);
    final isTime = widget.movement.dimension == MovementDimension.time;

    double fromDate(DateTime date) =>
        (date.year * 12 + date.month - 1).toDouble();

    DateTime fromValue(double value) {
      final intValue = value.round();
      final remainder = intValue % 12;
      final year = ((intValue - remainder) / 12).round();
      return DateTime(year, remainder + 1);
    }

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: _strengthSessionStats.map((s) {
              return FlSpot(fromDate(s.datetime), getValue(s));
            }).toList(),
            colors: [primaryColorOf(context)],
            dotData: FlDotData(show: false),
            isCurved: true,
            preventCurveOverShooting: true,
            preventCurveOvershootingThreshold: 1.5,
          ),
        ],
        titlesData: FlTitlesData(
          topTitles: SideTitles(showTitles: false),
          rightTitles: SideTitles(showTitles: false),
          bottomTitles: SideTitles(
            showTitles: true,
            getTitles: (value) {
              final date = fromValue(value);
              return shortMonthName(date.month) + '\n' + '${date.year}';
            },
          ),
          leftTitles: SideTitles(
            showTitles: true,
            reservedSize: isTime ? 60 : 40,
            getTitles: isTime
                ? (value) =>
                    Duration(milliseconds: value.round()).formatTimeWithMillis
                : null,
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          verticalInterval: 1,
          checkToShowVerticalLine: (value) => fromValue(value).month == 1,
          getDrawingVerticalLine: gridLineDrawer(context),
          getDrawingHorizontalLine: gridLineDrawer(context),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dataProvider.removeListener(_update);
    super.dispose();
  }
}
