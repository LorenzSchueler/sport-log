import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/pages/workout/charts/datetime_chart.dart';
import 'package:sport_log/pages/workout/charts/grid_line_drawer.dart';

/// needs to wrapped into something that constrains the size.
class DayChart extends DateTimePeriodChart {
  DayChart({
    required super.chartValues,
    required super.absolute,
    required super.formatter,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: chartValues
                .mapIndexed((index, v) => FlSpot(index + 1, v.value))
                .toList(),
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
        minX: 1,
        minY: minY,
        maxY: maxY,
        titlesData: titlesData(
          getBottomTitles: (value, _) => Text("Session ${value.round()}"),
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
