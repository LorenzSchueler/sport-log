import 'dart:math';

import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/pages/workout/charts/grid_line_drawer.dart';

class DurationChartValue {
  DurationChartValue({required this.duration, required this.value});

  Duration duration;
  double value;

  @override
  String toString() => "$duration: $value";
}

class DurationChartLine {
  DurationChartLine._(this.chartValues, this.lineColor);

  factory DurationChartLine.fromUngroupedChartValues({
    required List<DurationChartValue> ungroupedChartValues,
    required Color lineColor,
  }) {
    final List<DurationChartValue> chartValues = ungroupedChartValues
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
    final maxValue = chartValues.map((e) => e.value).maxOrNull;
    final minValue = chartValues.map((e) => e.value).minOrNull;
    if (maxValue != null && minValue != null) {
      final diff = maxValue - minValue;
      chartValues.map((chartValue) {
        if (diff > 0) {
          chartValue
            ..value -= minValue
            ..value /= diff;
        } else {
          chartValue.value = 0.5;
        }
        return chartValue;
      }).toList();
    }
    return DurationChartLine._(chartValues, lineColor);
  }

  factory DurationChartLine.fromDurationList({
    required List<Duration> durations,
    required Color lineColor,
  }) {
    final chartValues = durations
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
    final maxValue = chartValues.map((e) => e.value).maxOrNull;
    final minValue = chartValues.map((e) => e.value).minOrNull;
    if (maxValue != null && minValue != null) {
      final diff = maxValue - minValue;
      chartValues.map((chartValue) {
        if (diff > 0) {
          chartValue
            ..value -= minValue
            ..value /= diff;
        } else {
          chartValue.value = 0.5;
        }
        return chartValue;
      }).toList();
    }
    return DurationChartLine._(chartValues, lineColor);
  }

  final List<DurationChartValue> chartValues;
  final Color lineColor;

  static Duration _groupFunction(Duration duration) {
    // if max - min duration > ...
    return Duration(minutes: duration.inMinutes, seconds: 30);
  }
}

class DurationChart extends StatefulWidget {
  DurationChart({
    required this.chartLines,
    required this.yFromZero,
    this.touchCallback,
    this.height = 200,
    this.labelColor = Colors.white,
    super.key,
  })  : xInterval = chartLines
            .map(
              (chartLine) =>
                  max(
                    1.0,
                    (chartLine.chartValues.lastOrNull?.duration.inMinutes ??
                            0) /
                        6,
                  ).ceil().toDouble() *
                  60 *
                  1000,
            )
            .max,
        maxX = chartLines
            .map(
              (chartLine) =>
                  ((chartLine.chartValues.lastOrNull?.duration.inMinutes ?? 0) +
                      1) *
                  60 *
                  1000,
            )
            .max
            .toDouble();

  final List<DurationChartLine> chartLines;
  final bool yFromZero;
  final Function(Duration? x)? touchCallback;
  final double height;
  final Color labelColor;

  final double xInterval;
  final double maxX;

  @override
  State<DurationChart> createState() => _DurationChartState();
}

class _DurationChartState extends State<DurationChart> {
  double? lastX;

  void _onLongPress(FlTouchEvent event, LineTouchResponse? response) {
    if (event is FlLongPressStart || event is FlLongPressMoveUpdate) {
      final xValues = response?.lineBarSpots?.map((e) => e.x).toList();
      final xValue = xValues == null || xValues.isEmpty
          ? null
          : xValues[xValues.length ~/ 2]; // median
      if (xValue != null && xValue != lastX) {
        setState(() => lastX = xValue);
        widget.touchCallback?.call(Duration(milliseconds: xValue.round()));
      }
    } else if (event is FlLongPressEnd) {
      widget.touchCallback?.call(null);
      setState(() => lastX = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 5, 5, 0),
      child: SizedBox(
        height: widget.height,
        child: LineChart(
          LineChartData(
            lineBarsData: [
              for (final chartLine in widget.chartLines)
                LineChartBarData(
                  spots: chartLine.chartValues
                      .map(
                        (v) => FlSpot(
                          v.duration.inMilliseconds.toDouble(),
                          v.value,
                        ),
                      )
                      .toList(),
                  color: chartLine.lineColor,
                  dotData: FlDotData(show: false),
                ),
            ],
            minY: 0,
            maxY: 1,
            minX: 0.0,
            maxX: widget.maxX,
            extraLinesData: lastX == null
                ? null
                : ExtraLinesData(verticalLines: [VerticalLine(x: lastX!)]),
            lineTouchData: LineTouchData(
              enabled: false,
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
                  interval: widget.xInterval,
                  getTitlesWidget: (value, _) => Text(
                    value.round() % widget.xInterval.round() == 0 &&
                            value.round() > 0 &&
                            value.round() < widget.maxX
                        ? Duration(milliseconds: value.round()).formatHm
                        : "", // remove label at 0 and last value
                    style: TextStyle(color: widget.labelColor),
                  ),
                  reservedSize: 20,
                ),
              ),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              verticalInterval: widget.xInterval,
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
