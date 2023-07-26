import 'dart:math';

import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
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
    required this.absolute,
  }) : chartValues = chartValues
            .groupListsBy((v) => _groupFunction(v.distance))
            .entries
            .map(
              (entry) => DistanceChartValue(
                distance: entry.key,
                value: entry.value.map((v) => v.value).average,
              ),
            )
            .toList()
          ..sort((v1, v2) => v1.distance.compareTo(v2.distance));

  DistanceChartLine.fromDurationList({
    required List<double> distances,
    required this.lineColor,
    required this.absolute,
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
  final bool absolute;

  static double _groupFunction(double distance) {
    // if max - min duration > ...
    return (distance / 100).round() * 100 + 50;
  }

  @override
  String toString() => chartValues.map((e) => e.toString()).toString();
}

// ignore: must_be_immutable
class DistanceChart extends StatefulWidget {
  DistanceChart({
    required this.chartLines,
    this.touchCallback,
    this.labelColor = Colors.white,
    super.key,
  })  :
        // interval in m only at whole km at most 8
        _xInterval = chartLines
            .map(
              (chartLine) =>
                  max(
                    1,
                    (chartLine.chartValues.lastOrNull?.distance ?? 0) /
                        8 /
                        1000,
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
  final void Function(double? distance)? touchCallback;
  final Color labelColor;

  final double _xInterval;
  final double _minY;
  final double _maxY;

  @override
  State<DistanceChart> createState() => _DistanceChartState();
}

class _DistanceChartState extends State<DistanceChart> {
  double? _lastX;

  void _onLongPress(FlTouchEvent event, LineTouchResponse? response) {
    if (event is FlLongPressStart || event is FlLongPressMoveUpdate) {
      final xValues = response?.lineBarSpots?.map((e) => e.x).toList();
      final xValue = xValues == null || xValues.isEmpty
          ? null
          : xValues[xValues.length ~/ 2]; // median
      if (xValue != null && xValue != _lastX) {
        setState(() => _lastX = xValue);
        widget.touchCallback?.call(xValue);
      }
      _lastX = xValue;
    } else if (event is FlLongPressEnd) {
      widget.touchCallback?.call(null);
      setState(() => _lastX = null);
    }
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
          extraLinesData: _lastX == null
              ? null
              : ExtraLinesData(
                  verticalLines: [
                    VerticalLine(x: _lastX!, color: Colors.white)
                  ],
                ),
          lineTouchData: LineTouchData(
            enabled: false,
            touchSpotThreshold: double.infinity, // always get nearest point
            touchCallback: _onLongPress,
          ),
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
