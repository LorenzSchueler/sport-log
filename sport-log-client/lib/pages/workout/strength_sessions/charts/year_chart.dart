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
class YearChart extends StatefulWidget {
  YearChart({
    Key? key,
    required this.series,
    required DateTime start,
    required this.movement,
  })  : start = start.beginningOfYear(),
        super(key: key);

  final SeriesType series;
  final DateTime start;
  final Movement movement;

  @override
  State<YearChart> createState() => _YearChartState();
}

class _YearChartState extends State<YearChart> {
  final _dataProvider = StrengthSessionDescriptionDataProvider.instance;

  List<StrengthSessionStats> _strengthSessionStats = [];

  @override
  void initState() {
    super.initState();
    _dataProvider.addListener(update);
    update();
  }

  Future<void> update() async {
    final strengthSessionStats = await _dataProvider.getStatsAggregationsByWeek(
      movementId: widget.movement.id,
      from: widget.start,
      until: widget.start.yearLater(),
    );
    assert(strengthSessionStats.length <= 54);
    if (mounted) {
      setState(() => _strengthSessionStats = strengthSessionStats);
    }
  }

  @override
  void didUpdateWidget(YearChart oldWidget) {
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
            spots: _strengthSessionStats.map((s) {
              return FlSpot(
                  (s.datetime.difference(widget.start).inDays + 1).toDouble(),
                  getValue(s));
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
            interval: 1,
            checkToShowTitle: (_, __, ___, ____, value) {
              final date = DateTime(widget.start.year, 1, value.round());
              return date.day == 15;
            },
            getTitles: (value) => shortMonthName(
                DateTime(widget.start.year, 1, value.round()).month),
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
        minX: 0,
        maxX: (widget.start.isLeapYear ? 366 : 365).toDouble(),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          verticalInterval: 1,
          checkToShowVerticalLine: (value) =>
              DateTime(widget.start.year, 1, value.round()).day == 1,
          getDrawingVerticalLine: gridLineDrawer(context),
          getDrawingHorizontalLine: gridLineDrawer(context),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dataProvider.removeListener(update);
    super.dispose();
  }
}
