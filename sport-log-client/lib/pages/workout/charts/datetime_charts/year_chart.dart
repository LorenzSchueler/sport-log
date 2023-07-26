import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/pages/workout/charts/datetime_chart.dart';
import 'package:sport_log/pages/workout/charts/grid_line_drawer.dart';

/// needs to wrapped into something that constrains the size.
class YearChart extends DateTimePeriodChart {
  YearChart({
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
        minX: 1,
        maxX: startDateTime.numDaysInYear.toDouble(),
        minY: minY,
        maxY: maxY,
        titlesData: titlesData(
          getBottomTitles: (value, _) =>
              startDateTime.add(Duration(days: value.round())).day == 15
                  ? Text(
                      startDateTime
                          .add(Duration(days: value.round()))
                          .shortMonthName,
                    )
                  : const Text(""),
        ),
        gridData: FlGridData(
          getDrawingHorizontalLine: gridLineDrawer(),
          verticalInterval: 1,
          checkToShowVerticalLine: (value) =>
              startDateTime.add(Duration(days: value.round())).day == 1,
          getDrawingVerticalLine: gridLineDrawer(),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}
