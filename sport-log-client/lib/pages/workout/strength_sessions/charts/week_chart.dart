import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/helpers/extensions/iterable_extension.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/pages/workout/strength_sessions/charts/helpers.dart';

/// needs to wrapped into something that constrains the size (e. g. an [AspectRatio])
class WeekChart extends StatelessWidget {
  const WeekChart({
    required this.chartValues,
    required this.isTime,
    Key? key,
  }) : super(key: key);

  final List<ChartValue> chartValues;
  final bool isTime;

  @override
  Widget build(BuildContext context) {
    double maxY = chartValues.map((v) => v.value).max.ceil().toDouble();
    if (maxY == 0) {
      maxY = 1;
    }
    final start =
        chartValues.first.datetime.copyWith(hour: 0, minute: 0, second: 0);

    return chartValues.isEmpty
        ? const CircularProgressIndicator()
        : BarChart(
            BarChartData(
              barGroups: chartValues
                  .map(
                    (v) => BarChartGroupData(
                      x: v.datetime.difference(start).inDays + 1,
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
                    getTitlesWidget: (value, _) => Text(
                      shortWeekdayName(value.round()),
                    ),
                  ),
                ),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
