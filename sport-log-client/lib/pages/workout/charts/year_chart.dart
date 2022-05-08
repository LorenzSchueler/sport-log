import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/helpers/extensions/iterable_extension.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/pages/workout/charts/chart.dart';

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
    if (chartValues.isEmpty) {
      return const CircularProgressIndicator();
    } else {
      double maxY = chartValues.map((v) => v.value).max.ceil().toDouble();
      if (maxY == 0) {
        maxY = 1;
      }
      final start = chartValues.first.datetime.beginningOfYear();

      return LineChart(
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
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, _) =>
                    start.add(Duration(days: value.round())).day == 15
                        ? Text(
                            start
                                .add(Duration(days: value.round()))
                                .shortMonthName,
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
                start.add(Duration(days: value.round())).day == 1,
            getDrawingVerticalLine: gridLineDrawer(context),
            getDrawingHorizontalLine: gridLineDrawer(context),
          ),
          minX: 1.0,
          maxX: start.numDaysInYear.toDouble(),
          minY: 0.0,
          maxY: maxY,
          borderData: FlBorderData(show: false),
        ),
      );
    }
  }
}
