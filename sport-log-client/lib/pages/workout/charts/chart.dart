import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_state.dart';
import 'package:sport_log/pages/workout/charts/all.dart';

class ChartValue {
  final DateTime datetime;
  final double value;

  ChartValue({required this.datetime, required this.value});

  @override
  String toString() => "$datetime: $value";
}

class Chart extends StatelessWidget {
  const Chart({
    Key? key,
    required this.chartValues,
    required this.desc,
    required this.dateFilterState,
    required this.yFromZero,
  }) : super(key: key);

  final List<ChartValue> chartValues;
  final bool desc;
  final DateFilterState dateFilterState;
  final bool yFromZero;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.8,
      child: _chart(),
    );
  }

  Widget _chart() {
    final _chartValues = desc
        ? chartValues.reversed.toList() // data must be ordered asc datetime
        : chartValues;
    switch (dateFilterState.runtimeType) {
      case DayFilter:
        return DayChart(
          chartValues: _chartValues,
          isTime: false,
        );
      case WeekFilter:
        return WeekChart(
          chartValues: _chartValues,
          isTime: false,
        );
      case MonthFilter:
        return MonthChart(
          chartValues: _chartValues,
          yFromZero: yFromZero,
          isTime: false,
        );
      case YearFilter:
        return YearChart(
          chartValues: _chartValues,
          yFromZero: yFromZero,
          isTime: false,
        );
      default:
        return AllChart(
          chartValues: _chartValues,
          yFromZero: yFromZero,
          isTime: false,
        );
    }
  }
}

FlLine Function(double value) gridLineDrawer(BuildContext context) {
  return (value) => FlLine(
        color: Theme.of(context).colorScheme.primary,
        strokeWidth: 0.3,
        dashArray: [4, 4],
      );
}
