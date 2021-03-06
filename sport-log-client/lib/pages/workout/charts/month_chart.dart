import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/pages/workout/charts/datetime_chart.dart';
import 'package:sport_log/pages/workout/charts/grid_line_drawer.dart';

/// needs to wrapped into something that constrains the size (e. g. an [AspectRatio])
class MonthChart extends DateTimePeriodChart {
  MonthChart({
    required super.chartValues,
    required super.yFromZero,
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
                    v.datetime.difference(startDateTime).inDays + 1,
                    v.value,
                  ),
                )
                .toList(),
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
        minX: 1.0,
        maxX: startDateTime.numDaysInMonth.toDouble(),
        minY: minY,
        maxY: maxY,
        titlesData: titlesData(
          getBottomTitles: (value, _) =>
              value % 2 == 0 ? Text(value.round().toString()) : const Text(""),
        ),
        gridData: FlGridData(
          getDrawingHorizontalLine: gridLineDrawer(context: context),
          verticalInterval: 1,
          getDrawingVerticalLine: gridLineDrawer(context: context),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}
