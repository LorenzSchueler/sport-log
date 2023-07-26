import 'dart:math';

import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/pages/workout/charts/chart_helpers.dart';
import 'package:sport_log/pages/workout/charts/grid_line_drawer.dart';

class DurationChartValue {
  DurationChartValue({
    required this.duration,
    required this.value,
    required this.rawValue,
  });

  Duration duration;
  double value;
  double rawValue;

  @override
  String toString() => "$duration: $value ($rawValue)";
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
      getGroupValue: (durations, interval) =>
          durations.length.toDouble() / interval.inMinuteFractions,
      getLastGroupValue: (durations, interval) =>
          durations.length.toDouble() *
          (interval.inMilliseconds /
              (durations.last.inMilliseconds % interval.inMilliseconds)) /
          interval.inMinuteFractions,
      lineColor: lineColor,
      absolute: absolute,
    );
  }

  // ignore: long-parameter-list
  static DurationChartLine fromValues<T>({
    required List<T>? values,
    required Duration Function(T) getDuration,
    required double Function(List<T>, Duration interval) getGroupValue,
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
          (el) => groupFunction(getDuration(el), totalDuration),
        )
        .entries;
    final chartValues = groupedValues.map((entry) {
      final value = getGroupValue(entry.value, interval);
      return DurationChartValue(
        duration: entry.key,
        value: value,
        rawValue: value,
      );
    }).toList();
    if (getLastGroupValue != null) {
      final value = getLastGroupValue(groupedValues.last.value, interval);
      chartValues.last = DurationChartValue(
        duration: groupedValues.last.key,
        value: value,
        rawValue: value,
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

  static Duration groupFunction(Duration duration, Duration totalDuration) {
    final intervalMin = intervalMinutes(totalDuration).inMinutes;
    return Duration(minutes: duration.inMinutes ~/ intervalMin * intervalMin);
  }

  // 0h - 1h: 1 min -> 0 - 60 points
  // 1h - 2h: 2 min -> 30 - 60 points
  // 2h - 3h: 3 min -> 40 - 60 points
  static Duration intervalMinutes(Duration totalDuration) =>
      Duration(minutes: totalDuration.inHours + 1);
}

class DurationChart extends StatefulWidget {
  DurationChart({
    required this.chartLines,
    this.touchCallback,
    this.labelColor = Colors.white,
    super.key,
  })  : _xInterval = chartLines
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
        _maxX = chartLines
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
  final Color labelColor;

  final double _xInterval;
  final double _maxX;

  @override
  State<DurationChart> createState() => _DurationChartState();
}

class _DurationChartState extends State<DurationChart> {
  double? _lastX;

  void _onLongPress(double? xValue) {
    setState(() => _lastX = xValue);
    widget.touchCallback
        ?.call(xValue == null ? null : Duration(milliseconds: xValue.round()));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 5, 5, 0),
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
                dotData: const FlDotData(show: false),
                isCurved: true,
                preventCurveOverShooting: true,
              ),
          ],
          minY: 0,
          maxY: 1,
          minX: 0,
          maxX: widget._maxX,
          extraLinesData: touchLine(_lastX),
          lineTouchData: touchCallback(_onLongPress),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: widget._xInterval,
                getTitlesWidget: (value, _) => Text(
                  value.round() % widget._xInterval.round() == 0 &&
                          value.round() > 0 &&
                          value.round() < widget._maxX
                      ? Duration(milliseconds: value.round()).formatHm
                      : "", // remove label at 0 and last value
                  style: TextStyle(color: widget.labelColor),
                ),
                reservedSize: 20,
              ),
            ),
            leftTitles: const AxisTitles(),
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
