import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/helpers/extensions/iterable_extension.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/pages/workout/charts/helpers.dart';

/// needs to wrapped into something that constrains the size (e. g. an [AspectRatio])
class YearChart extends StatelessWidget {
  const YearChart({
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
        : LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: chartValues
                      .map(
                        (v) => FlSpot(
                          v.datetime.difference(start).inDays + 1,
                          v.value,
                        ),
                      )
                      .toList(),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
              titlesData: FlTitlesData(
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, _) => DateTime(
                              start.year,
                              1,
                              value.round(),
                            ).day ==
                            15
                        ? Text(
                            DateTime(
                              start.year,
                              1,
                              value.round(),
                            ).shortMonthName,
                          )
                        : const Text(""),
                  ),
                ),
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
              ),
              gridData: FlGridData(
                verticalInterval: 1,
                checkToShowVerticalLine: (value) =>
                    DateTime(start.year, 1, value.round()).day == 1,
                getDrawingVerticalLine: gridLineDrawer(context),
                getDrawingHorizontalLine: gridLineDrawer(context),
              ),
              minX: 1.0,
              maxX: (start.isLeapYear ? 366 : 365).toDouble(),
              minY: 0.0,
              maxY: maxY,
              borderData: FlBorderData(show: false),
            ),
          );
  }
}
