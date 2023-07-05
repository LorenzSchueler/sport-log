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

  factory DurationChartLine._fromNonNormalizedDurationChartLine(
    List<DurationChartValue> chartValues,
    Color lineColor,
    bool absolute,
  ) {
    if (chartValues.isEmpty) {
      return DurationChartLine._([], lineColor);
    }
    final maxValue = chartValues.map((e) => e.value).max;
    final minValue = absolute ? 0 : chartValues.map((e) => e.value).min;
    final diff = maxValue - minValue;
    for (final chartValue in chartValues) {
      if (diff > 0) {
        chartValue
          ..value -= minValue
          ..value /= diff;
      } else {
        chartValue.value = 0.5;
      }
    }
    return DurationChartLine._(chartValues, lineColor);
  }

  factory DurationChartLine.fromDurationList({
    required List<Duration>? durations,
    required Color lineColor,
    required bool absolute,
  }) {
    return DurationChartLine.fromValues(
      values: durations,
      getDuration: (d) => d,
      getGroupValue: (durations) => durations.length.toDouble(),
      getLastGroupValue: (durations, interval) =>
          durations.length.toDouble() *
          (interval.inMilliseconds /
              (durations.last.inMilliseconds % interval.inMilliseconds)),
      lineColor: lineColor,
      absolute: absolute,
    );
  }

  // ignore: long-parameter-list
  static DurationChartLine fromValues<T>({
    required List<T>? values,
    required Duration Function(T) getDuration,
    required double Function(List<T>) getGroupValue,
    double Function(List<T>, Duration interval)? getLastGroupValue,
    required Color lineColor,
    required bool absolute,
  }) {
    if (values == null || values.isEmpty) {
      return DurationChartLine._([], lineColor);
    }
    final totalDuration = getDuration(values.last);
    final interval = intervalMinutes(totalDuration);
    final groupedValues = values
        .groupListsBy(
          (el) => _groupFunction(getDuration(el), interval.inMinutes),
        )
        .entries;
    final chartValues = groupedValues
        .map(
          (entry) => DurationChartValue(
            duration: entry.key,
            value: getGroupValue(entry.value),
          ),
        )
        .toList();
    if (getLastGroupValue != null) {
      chartValues.last = DurationChartValue(
        duration: groupedValues.last.key,
        value: getLastGroupValue(groupedValues.last.value, interval),
      );
    }
    chartValues.sort((v1, v2) => v1.duration.compareTo(v2.duration));
    return DurationChartLine._fromNonNormalizedDurationChartLine(
      chartValues,
      lineColor,
      absolute,
    );
  }

  final List<DurationChartValue> chartValues;
  final Color lineColor;

  static Duration _groupFunction(Duration duration, int intervalMin) =>
      Duration(minutes: duration.inMinutes ~/ intervalMin * intervalMin);

  static Duration intervalMinutes(Duration totalDuration) =>
      Duration(minutes: totalDuration.inHours + 1);
}

class DurationChart extends StatefulWidget {
  DurationChart({
    required this.chartLines,
    this.touchCallback,
    this.height = 200,
    this.labelColor = Colors.white,
    super.key,
  })  : xInterval = chartLines
            .map(
              (chartLine) =>
                  max(
                    1,
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
                  (chartLine.chartValues.lastOrNull?.duration.inMinutes ?? 0) *
                  60 *
                  1000,
            )
            .max
            .toDouble();

  final List<DurationChartLine> chartLines;
  final void Function(Duration? x)? touchCallback;
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
                  isCurved: true,
                  preventCurveOverShooting: true,
                ),
            ],
            minY: 0,
            maxY: 1,
            minX: 0,
            maxX: widget.maxX,
            extraLinesData: lastX == null
                ? null
                : ExtraLinesData(
                    verticalLines: [
                      VerticalLine(x: lastX!, color: Colors.white)
                    ],
                  ),
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
              getDrawingHorizontalLine:
                  gridLineDrawer(context: context, color: Colors.grey),
              verticalInterval: widget.xInterval,
              getDrawingVerticalLine:
                  gridLineDrawer(context: context, color: Colors.grey),
            ),
            borderData: FlBorderData(show: false),
          ),
        ),
      ),
    );
  }
}
