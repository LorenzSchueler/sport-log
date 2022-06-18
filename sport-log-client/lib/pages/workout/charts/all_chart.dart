import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/pages/workout/charts/datetime_chart.dart';
import 'package:sport_log/pages/workout/charts/grid_line_drawer.dart';

/// needs to wrapped into something that constrains the size (e. g. an [AspectRatio])
class AllChart extends DateTimePeriodChart {
  AllChart({
    required super.chartValues,
    required super.yFromZero,
    required super.isTime,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final startDateTime = chartValues.firstOrNull?.datetime.beginningOfDay() ??
        DateTime.now().beginningOfYear();
    final endDateTime =
        chartValues.lastOrNull?.datetime ?? DateTime.now().endOfYear();
    final months = (endDateTime.difference(startDateTime).inDays / 30).round();
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
                      v.datetime.difference(startDateTime).inDays + 1,
                      v.value,
                    ),
                  )
                  .toList(),
              color: Theme.of(context).colorScheme.primary,
              dotData: FlDotData(show: false),
            ),
          ],
          minY: minY,
          maxY: maxY,
          titlesData: titlesData(
            getBottomTitles: (value, _) {
              final date = startDateTime.add(Duration(days: value.round()));
              return date.day == 15 && markedMonths.contains(date.month)
                  ? Text("${date.shortMonthName}\n${date.year}")
                  : const Text("");
            },
            reservedSize: 35,
          ),
          gridData: FlGridData(
            getDrawingHorizontalLine: gridLineDrawer(context),
            verticalInterval: 1,
            checkToShowVerticalLine: (value) {
              final datetime = startDateTime.add(Duration(days: value.round()));
              return datetime.day == 1 && markedMonths.contains(datetime.month)
                  ? true
                  : false;
            },
            getDrawingVerticalLine: gridLineDrawer(context),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}
