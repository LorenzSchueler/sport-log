import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/helpers/extensions/iterable_extension.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/pages/workout/charts/helpers.dart';

/// needs to wrapped into something that constrains the size (e. g. an [AspectRatio])
class DayChart extends StatelessWidget {
  const DayChart({
    required this.chartValues,
    required this.isTime,
    Key? key,
  }) : super(key: key);

  final List<ChartValue> chartValues;
  final bool isTime;

  @override
  Widget build(BuildContext context) {
    if (chartValues.isEmpty) {
      return const CircularProgressIndicator();
    } else {
      double maxY = chartValues.map((v) => v.value).max.ceil().toDouble();
      if (maxY == 0) {
        maxY = 1;
      }

      return BarChart(
        BarChartData(
          barGroups: chartValues
              .mapIndexed(
                (v, index) => BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: v.value,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  ],
                ),
              )
              .toList(),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: isTime ? 60 : 30,
                getTitlesWidget: isTime
                    ? (value, _) => Text(
                          Duration(milliseconds: value.round())
                              .formatTimeWithMillis,
                        )
                    : null,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) => Text("Set ${value.round() + 1}"),
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            getDrawingHorizontalLine: gridLineDrawer(context),
            drawVerticalLine: false,
          ),
        ),
      );
    }
  }
}
