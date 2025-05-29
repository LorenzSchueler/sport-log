import 'dart:math';

import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/pages/workout/charts/chart_helpers.dart';
import 'package:sport_log/pages/workout/charts/grid_line_drawer.dart';

class DistanceChartValue {
  DistanceChartValue({required this.distance, required this.value});

  final double distance;
  final double value;

  @override
  String toString() => "$distance: $value";
}

class DistanceChartLine {
  DistanceChartLine._(this.chartValues, this.lineColor, this.absolute);

  static DistanceChartLine fromValues<T>({
    required List<T>? values,
    required double Function(T v) getDistance,
    required double Function(T v) getValue,
    required Color lineColor,
    required bool absolute,
  }) {
    if (values == null || values.isEmpty) {
      return DistanceChartLine._([], lineColor, absolute);
    }
    final totalDistance = getDistance(values.last);
    final chartValues =
        values
            .groupListsBy(
              (value) => _groupFunction(getDistance(value), totalDistance),
            )
            .entries
            .map(
              (entry) => DistanceChartValue(
                distance: entry.key,
                value: entry.value.map((v) => getValue(v)).average,
              ),
            )
            .toList()
          ..sort((v1, v2) => v1.distance.compareTo(v2.distance));
    return DistanceChartLine._(chartValues, lineColor, absolute);
  }

  final List<DistanceChartValue> chartValues;
  final Color lineColor;
  final bool absolute;

  static double _groupFunction(double distance, double totalDistance) {
    final interval = intervalMeter(totalDistance);
    return (distance / interval).round() * interval;
  }

  static double intervalMeter(double totalDistance) => totalDistance / 100;
}

class DistanceChart extends StatefulWidget {
  DistanceChart({
    required this.chartLines,
    required this.touchCallback,
    this.labelColor = Colors.white,
    super.key,
  }) : // interval in m only at whole km at most 8
       _xInterval = chartLines
           .map(
             (chartLine) =>
                 max(
                   1,
                   (chartLine.chartValues.lastOrNull?.distance ?? 0) / 8 / 1000,
                 ).ceil().toDouble() *
                 1000,
           )
           .max,
       _minY = chartLines
           .map(
             (chartLine) => chartLine.absolute
                 ? 0.0
                 : chartLine.chartValues.map((v) => v.value).minOrNull ?? 0,
           )
           .min,
       _maxY = chartLines
           .map(
             (chartLine) =>
                 chartLine.chartValues.map((v) => v.value).maxOrNull ?? 0,
           )
           .max;

  final List<DistanceChartLine> chartLines;
  final void Function(double? distance) touchCallback;
  final Color labelColor;

  final double _xInterval;
  final double _minY;
  final double _maxY;

  @override
  State<DistanceChart> createState() => _DistanceChartState();
}

class _DistanceChartState extends State<DistanceChart> {
  double? _lastX;

  void _onLongPress(double? xValue) {
    setState(() => _lastX = xValue);
    widget.touchCallback(xValue);
  }

  @override
  Widget build(BuildContext context) {
    var minY = widget._minY;
    var maxY = widget._maxY;
    if (widget._maxY == widget._minY) {
      maxY += 1;
      minY -= 1;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 10, 15, 0),
      child: LineChart(
        LineChartData(
          lineBarsData: [
            for (final chartLine in widget.chartLines)
              LineChartBarData(
                spots: chartLine.chartValues
                    .map((v) => FlSpot(v.distance, v.value))
                    .toList(),
                color: chartLine.lineColor,
                dotData: const FlDotData(show: false),
                isCurved: true,
                preventCurveOverShooting: true,
              ),
          ],
          minY: minY,
          maxY: maxY,
          minX: 0,
          extraLinesData: touchLine(_lastX),
          lineTouchData: touchCallback(_onLongPress),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: widget._xInterval,
                getTitlesWidget: (m, _) => Text(
                  m.round() % widget._xInterval.round() == 0
                      ? (m / 1000).round().toString()
                      : "", // remove label at last value
                  style: TextStyle(color: widget.labelColor),
                ),
                reservedSize: 20,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, _) => Text(
                  value.round().toString(),
                  style: TextStyle(color: widget.labelColor),
                ),
              ),
            ),
          ),
          gridData: FlGridData(
            getDrawingHorizontalLine: gridLineDrawer(),
            verticalInterval: widget._xInterval,
            getDrawingVerticalLine: gridLineDrawer(),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}
