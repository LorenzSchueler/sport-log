import 'dart:math';

import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/helpers/extensions/double_extension.dart';
import 'package:sport_log/pages/workout/charts/grid_line_drawer.dart';

class DistanceChartValue {
  DistanceChartValue({required this.distance, required this.value});

  final double distance;
  final double value;

  @override
  String toString() => "$distance: $value";
}

class DistanceChartLine {
  DistanceChartLine.fromUngroupedChartValues({
    required List<DistanceChartValue> chartValues,
    required this.lineColor,
  }) : chartValues = chartValues
            .groupListsBy((v) => _groupFunction(v.distance))
            .entries
            .map(
              (entry) => DistanceChartValue(
                distance: entry.key,
                value:
                    entry.value.map((v) => v.value).average.roundToPrecision(1),
              ),
            )
            .toList()
          ..sort((v1, v2) => v1.distance.compareTo(v2.distance));

  DistanceChartLine.fromDurationList({
    required List<double> distances,
    required this.lineColor,
  }) : chartValues = distances
            .groupListsBy(_groupFunction)
            .entries
            .map(
              (entry) => DistanceChartValue(
                distance: entry.key,
                value: entry.value.length.toDouble(),
              ),
            )
            .toList()
          ..sort((v1, v2) => v1.distance.compareTo(v2.distance));

  final List<DistanceChartValue> chartValues;
  final Color lineColor;

  static double _groupFunction(double distance) {
    // if max - min duration > ...
    return (distance / 100).round() * 100 + 50;
  }

  @override
  String toString() => chartValues.map((e) => e.toString()).toString();
}

// ignore: must_be_immutable
class DistanceChart extends StatelessWidget {
  DistanceChart({
    required this.chartLines,
    required this.yFromZero,
    this.touchCallback,
    this.height = 200,
    this.labelColor = Colors.white,
    super.key,
  });

  final List<DistanceChartLine> chartLines;
  final bool yFromZero;
  final Function(double? distance)? touchCallback;
  final double height;
  final Color labelColor;

  double? lastX;

  void _onLongPress(FlTouchEvent event, LineTouchResponse? response) {
    if (event is FlLongPressStart || event is FlLongPressMoveUpdate) {
      final xValues = response?.lineBarSpots?.map((e) => e.x).toList();
      final xValue = xValues == null || xValues.isEmpty
          ? null
          : xValues[xValues.length ~/ 2]; // median
      if (xValue != null && xValue != lastX) {
        touchCallback?.call(xValue * 1000);
      }
      lastX = xValue;
    } else if (event is FlLongPressEnd) {
      touchCallback?.call(null);
      lastX = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    double minY = yFromZero
        ? 0.0
        : chartLines
            .map(
              (chartLine) =>
                  chartLine.chartValues.map((v) => v.value).minOrNull ?? 0,
            )
            .min;
    double maxY = chartLines
        .map(
          (chartLine) =>
              chartLine.chartValues.map((v) => v.value).maxOrNull ?? 0,
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
                (chartLine.chartValues.lastOrNull?.distance ?? 0) / 8 / 100,
              ).ceil().toDouble() *
              100,
        )
        .max;

    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 10, 15, 0),
      child: SizedBox(
        height: height,
        child: LineChart(
          LineChartData(
            lineBarsData: [
              for (final chartLine in chartLines)
                LineChartBarData(
                  spots: chartLine.chartValues
                      .map(
                        (v) => FlSpot(
                          v.distance / 1000,
                          v.value,
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
            lineTouchData: LineTouchData(
              touchSpotThreshold: double.infinity, // always get nearest point
              touchCallback: _onLongPress,
            ),
            titlesData: FlTitlesData(
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: xInterval / 1000,
                  getTitlesWidget: (km, _) => Text(
                    (km * 1000).round() % xInterval.round() == 0
                        ? km.toStringAsFixed(1)
                        : "", // remove label at last value
                    style: TextStyle(color: labelColor),
                  ),
                  reservedSize: 20,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, _) => Text(
                    value.round().toString(),
                    style: TextStyle(color: labelColor),
                  ),
                ),
              ),
            ),
            gridData: FlGridData(
              getDrawingHorizontalLine:
                  gridLineDrawer(context: context, color: Colors.black),
              verticalInterval: xInterval,
              getDrawingVerticalLine:
                  gridLineDrawer(context: context, color: Colors.black),
            ),
            borderData: FlBorderData(show: false),
          ),
        ),
      ),
    );
  }
}
