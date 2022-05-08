import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/extensions/iterable_extension.dart';
import 'package:sport_log/pages/workout/charts/helpers.dart';

/// needs to wrapped into something that constrains the size (e. g. an [AspectRatio])
class AllChart extends StatelessWidget {
  const AllChart({
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
      final start =
          chartValues.first.datetime.copyWith(hour: 0, minute: 0, second: 0);
      final end = chartValues.last.datetime;
      final months = (end.difference(start).inDays / 30).round();
      final titleInterval = (months / 8).ceil();
      final List<int> markedMonths;
      if (titleInterval == 1) {
        markedMonths = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
      } else if (titleInterval == 2) {
        markedMonths = [1, 3, 5, 7, 9, 11];
      } else if (titleInterval == 3) {
        markedMonths = [1, 4, 7, 10];
      } else if (titleInterval == 4) {
        markedMonths = [1, 5, 9];
      } else if (titleInterval <= 6) {
        markedMonths = [1, 7];
      } else {
        markedMonths = [1];
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 5, 15, 0),
        child: LineChart(
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
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (value, _) {
                    final date = start.add(Duration(days: value.round()));
                    return date.day == 15 && markedMonths.contains(date.month)
                        ? Text("${date.shortMonthName}\n${date.year}")
                        : const Text("");
                  },
                  reservedSize: 35,
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
              checkToShowVerticalLine: (value) {
                final datetime = start.add(Duration(days: value.round()));
                return datetime.day == 1 &&
                        markedMonths.contains(datetime.month)
                    ? true
                    : false;
              },
              getDrawingVerticalLine: gridLineDrawer(context),
              getDrawingHorizontalLine: gridLineDrawer(context),
            ),
            minY: 0.0,
            maxY: maxY,
            borderData: FlBorderData(show: false),
          ),
        ),
      );
    }
  }
}
