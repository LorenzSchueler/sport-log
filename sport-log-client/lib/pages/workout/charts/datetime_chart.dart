import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/pages/workout/charts/all.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_state.dart';

class DateTimeChartValue {
  DateTimeChartValue({required this.datetime, required this.value});

  final DateTime datetime;
  final double value;

  @override
  String toString() => "$datetime: $value";
}

enum AggregatorType {
  min,
  max,
  sum,
  avg,
  none;

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

class DateTimeChart extends StatelessWidget {
  const DateTimeChart({
    required this.chartValues,
    required this.dateFilterState,
    required this.yFromZero,
    required this.aggregatorType,
    super.key,
  });

  final List<DateTimeChartValue> chartValues;
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
          (entry) => DateTimeChartValue(
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

abstract class DateTimePeriodChart extends StatelessWidget {
  DateTimePeriodChart({
    required this.chartValues,
    required this.yFromZero,
    required this.isTime,
    super.key,
  })  : _maxY =
            (chartValues.map((v) => v.value).maxOrNull ?? 0).ceil().toDouble(),
        _minY = yFromZero
            ? 0.0
            : (chartValues.map((v) => v.value).minOrNull ?? 0)
                .floor()
                .toDouble();

  final List<DateTimeChartValue> chartValues;
  final bool isTime;
  final bool yFromZero;
  final double _maxY;
  final double _minY;

  double get maxY => _maxY == _minY ? _maxY + 1 : _maxY;

  double get minY => _maxY == _minY ? _minY - 1 : _minY;

  FlTitlesData titlesData({
    Widget Function(double, TitleMeta)? getBottomTitles,
    double? reservedSize,
  }) =>
      FlTitlesData(
        topTitles: _noAxisTitles,
        rightTitles: _noAxisTitles,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: getBottomTitles,
            reservedSize: reservedSize,
          ),
        ),
        leftTitles: _leftAxisTitles,
      );

  static final AxisTitles _noAxisTitles =
      AxisTitles(sideTitles: SideTitles(showTitles: false));

  AxisTitles get _leftAxisTitles {
    return AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: isTime ? 60 : 40,
        getTitlesWidget: isTime
            ? (value, _) =>
                Text(Duration(milliseconds: value.round()).formatMsMill)
            : null,
      ),
    );
  }
}
