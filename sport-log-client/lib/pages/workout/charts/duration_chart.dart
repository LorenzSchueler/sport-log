import 'dart:math';

import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/pages/workout/charts/grid_line_drawer.dart';

class DurationChartValue {
  DurationChartValue({required this.duration, required this.value});

  final Duration duration;
  final double value;

  @override
  String toString() => "$duration: $value";
}

class DurationChartLine {
  DurationChartLine.fromUngroupedChartValues({
    required List<DurationChartValue> chartValues,
    required this.lineColor,
    required this.isRight,
  }) : chartValues = chartValues
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

  DurationChartLine.fromDurationList({
    required List<Duration> durations,
    required this.lineColor,
    required this.isRight,
  }) : chartValues = durations
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

  final List<DurationChartValue> chartValues;
  final Color lineColor;
  final bool isRight;

  int yScaleFactor(int yScaleFactor) => isRight ? yScaleFactor : 1;

  static Duration _groupFunction(Duration duration) {
    // if max - min duration > ...
    return Duration(minutes: duration.inMinutes, seconds: 30);
  }
}

class DurationChart extends StatelessWidget {
  const DurationChart({
    required this.chartLines,
    required this.yFromZero,
    required this.rightYScaleFactor,
    this.touchCallback,
    super.key,
  });

  final List<DurationChartLine> chartLines;
  final bool yFromZero;
  final int rightYScaleFactor;
  final Function(List<double>? x, List<double>? y)? touchCallback;

  @override
  Widget build(BuildContext context) {
    double minY = yFromZero
        ? 0.0
        : chartLines
            .map(
              (chartLine) =>
                  (chartLine.chartValues.map((v) => v.value).minOrNull ?? 0) /
                  chartLine.yScaleFactor(rightYScaleFactor).floor().toDouble(),
            )
            .min;
    double maxY = chartLines
        .map(
          (chartLine) =>
              (chartLine.chartValues.map((v) => v.value).maxOrNull ?? 0) /
              chartLine.yScaleFactor(rightYScaleFactor).ceil().toDouble(),
        )
        .max;
    if (maxY == minY) {
      maxY += 1;
      minY -= 1;
    }

    double xInterval = chartLines
        .map(
          (chartLine) =>
              max(
                1.0,
                (chartLine.chartValues.lastOrNull?.duration.inMinutes ?? 0) / 6,
              ).ceil().toDouble() *
              60 *
              1000,
        )
        .max;
    double maxX = chartLines
        .map(
          (chartLine) =>
              ((chartLine.chartValues.lastOrNull?.duration.inMinutes ?? 0) +
                  1) *
              60 *
              1000,
        )
        .max
        .toDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 0, 25, 0),
      child: AspectRatio(
        aspectRatio: 1.8,
        child: LineChart(
          LineChartData(
            lineBarsData: [
              for (final chartLine in chartLines)
                LineChartBarData(
                  spots: chartLine.chartValues
                      .map(
                        (v) => FlSpot(
                          v.duration.inMilliseconds.toDouble(),
                          v.value / chartLine.yScaleFactor(rightYScaleFactor),
                        ),
                      )
                      .toList(),
                  color: chartLine.lineColor,
                  dotData: FlDotData(show: false),
                ),
            ],
            minY: minY,
            maxY: maxY,
            minX: 0.0,
            maxX: maxX,
            lineTouchData: LineTouchData(
              touchSpotThreshold: double.infinity, // always get nearest point
              touchCallback: (event, response) {
                if (event is FlPanDownEvent || event is FlPanUpdateEvent) {
                  final yValues =
                      response?.lineBarSpots?.map((e) => e.y).toList();
                  final xValues =
                      response?.lineBarSpots?.map((e) => e.x).toList();
                  touchCallback?.call(xValues, yValues);
                } else if (event is FlPanCancelEvent ||
                    event is FlPanEndEvent) {
                  touchCallback?.call(null, null);
                }
              },
            ),
            titlesData: FlTitlesData(
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, _) =>
                      Text((value * rightYScaleFactor).round().toString()),
                ),
              ),
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
