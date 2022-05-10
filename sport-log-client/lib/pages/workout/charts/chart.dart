import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_state.dart';
import 'package:sport_log/pages/workout/charts/all.dart';

class ChartValue {
  final DateTime datetime;
  final double value;

  ChartValue({required this.datetime, required this.value});

  @override
  String toString() => "$datetime: $value";
}

enum AggregatorType {
  min,
  max,
  sum,
  avg,
  none,
}

extension on AggregatorType {
  /// list must not be empty
  double compute(Iterable<double> list) {
    switch (this) {
      case AggregatorType.min:
        return list.minOrNull ?? 0;
      case AggregatorType.max:
        return list.maxOrNull ?? 0;
      case AggregatorType.sum:
        return list.sum;
      case AggregatorType.avg:
        return list.average;
      case AggregatorType.none:
        return list.first;
    }
  }
}

class Chart extends StatelessWidget {
  const Chart({
    Key? key,
    required this.chartValues,
    required this.desc,
    required this.dateFilterState,
    required this.yFromZero,
    required this.aggregatorType,
  }) : super(key: key);

  final List<ChartValue> chartValues;
  final bool desc;
  final DateFilterState dateFilterState;
  final bool yFromZero;
  final AggregatorType aggregatorType;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.8,
      child: _chart(),
    );
  }

  Widget _chart() {
    final chartValues = this
        .chartValues
        .groupListsBy((v) => _groupFunction(v.datetime))
        .entries
        .map(
          (entry) => ChartValue(
            datetime: entry.key,
            value: aggregatorType.compute(entry.value.map((e) => e.value)),
          ),
        )
        .toList()
      ..sort((v1, v2) => v1.datetime.compareTo(v2.datetime));
    switch (dateFilterState.runtimeType) {
      case DayFilter:
        return DayChart(
          chartValues: chartValues,
          yFromZero: yFromZero,
          isTime: false,
        );
      case WeekFilter:
        return WeekChart(
          chartValues: chartValues,
          yFromZero: yFromZero,
          isTime: false,
          startDateTime: dateFilterState.start!,
        );
      case MonthFilter:
        return MonthChart(
          chartValues: chartValues,
          yFromZero: yFromZero,
          isTime: false,
          startDateTime: dateFilterState.start!,
        );
      case YearFilter:
        return YearChart(
          chartValues: chartValues,
          yFromZero: yFromZero,
          isTime: false,
          startDateTime: dateFilterState.start!,
        );
      default:
        return AllChart(
          chartValues: chartValues,
          yFromZero: yFromZero,
          isTime: false,
        );
    }
  }

  DateTime _groupFunction(DateTime dateTime) {
    switch (dateFilterState.runtimeType) {
      case DayFilter:
        return dateTime;
      case WeekFilter:
        return dateTime.beginningOfDay();
      case MonthFilter:
        return dateTime.beginningOfDay();
      case YearFilter:
        return dateTime.beginningOfMonth().add(const Duration(days: 15));
      default:
        return dateTime.beginningOfMonth().add(const Duration(days: 15));
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
