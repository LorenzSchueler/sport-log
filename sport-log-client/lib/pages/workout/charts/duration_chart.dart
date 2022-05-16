import 'dart:math';

import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/pages/workout/charts/grid_line_drawer.dart';

class DurationChartValue {
  final Duration duration;
  final double value;

  DurationChartValue({required this.duration, required this.value});

  @override
  String toString() => "$duration: $value";

  static List<DurationChartValue> listFromDurationList(
    List<Duration> durations,
  ) {
    return durations
        .groupListsBy(_groupFunction)
        .entries
        .map(
          (entry) => DurationChartValue(
            duration: entry.key,
            value: entry.value.length.toDouble(),
          ),
        )
        .toList()
      ..sort((v1, v2) => v1.duration.compareTo(v2.duration));
  }

  static List<DurationChartValue> groupedChartValueList(
    List<DurationChartValue> chartValues,
  ) {
    return chartValues
        .groupListsBy((v) => _groupFunction(v.duration))
        .entries
        .map(
          (entry) => DurationChartValue(
            duration: entry.key,
            value: entry.value.map((v) => v.value).average,
          ),
        )
        .toList()
      ..sort((v1, v2) => v1.duration.compareTo(v2.duration));
  }

  static Duration _groupFunction(Duration duration) {
    // if max - min duration > ...
    return Duration(minutes: duration.inMinutes, seconds: 30);
  }
}

class DurationChart extends StatelessWidget {
  const DurationChart({
    Key? key,
    required this.chartValues,
    required this.yFromZero,
  }) : super(key: key);

  final List<DurationChartValue> chartValues;
  final bool yFromZero;

  @override
  Widget build(BuildContext context) {
    double minY = yFromZero
        ? 0.0
        : (chartValues.map((v) => v.value).minOrNull ?? 0).floor().toDouble();
    double maxY =
        (chartValues.map((v) => v.value).maxOrNull ?? 0).ceil().toDouble();
    if (maxY == minY) {
      maxY += 1;
      minY -= 1;
    }

    double xInterval =
        max(1.0, (chartValues.lastOrNull?.duration.inMinutes ?? 0) / 6)
                .ceil()
                .toDouble() *
            60 *
            1000;
    double maxX =
        ((chartValues.lastOrNull?.duration.inMinutes ?? 0) + 1) * 60 * 1000;

    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 0, 25, 5),
      child: AspectRatio(
        aspectRatio: 1.8,
        child: LineChart(
          LineChartData(
            lineBarsData: [
              LineChartBarData(
                spots: chartValues
                    .map(
                      (v) =>
                          FlSpot(v.duration.inMilliseconds.toDouble(), v.value),
                    )
                    .toList(),
                color: Theme.of(context).colorScheme.primary,
                dotData: FlDotData(show: false),
              ),
            ],
            minY: minY,
            maxY: maxY,
            minX: 0.0,
            maxX: maxX,
            titlesData: FlTitlesData(
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: xInterval,
                  getTitlesWidget: (value, _) => Text(
                    value.round() % xInterval.round() == 0
                        ? Duration(milliseconds: value.round()).formatHm
                        : "", // remove label at last value
                  ),
                  reservedSize: 35,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                ),
              ),
            ),
            gridData: FlGridData(
              getDrawingHorizontalLine: gridLineDrawer(context),
              verticalInterval: xInterval,
              getDrawingVerticalLine: gridLineDrawer(context),
            ),
            borderData: FlBorderData(show: false),
          ),
        ),
      ),
    );
  }
}
