import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/pages/workout/charts/datetime_chart.dart';
import 'package:sport_log/pages/workout/charts/grid_line_drawer.dart';

/// needs to wrapped into something that constrains the size.
class WeekChart extends DateTimePeriodChart {
  WeekChart({
    required super.chartValues,
    required super.absolute,
    required super.isTime,
    required this.startDateTime,
    super.key,
  });

  final DateTime startDateTime;

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: chartValues
                .map(
                  (v) => FlSpot(
                    v.datetime.difference(startDateTime).inDays.toDouble(),
                    v.value,
                  ),
                )
                .toList(),
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
        minX: 0,
        maxX: 6,
        minY: minY,
        maxY: maxY,
        titlesData: titlesData(
          getBottomTitles: (value, _) => Text(
            startDateTime.add(Duration(days: value.round())).shortWeekdayName,
          ),
        ),
        gridData: FlGridData(
          getDrawingHorizontalLine: gridLineDrawer(),
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}
