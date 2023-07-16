import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/pages/workout/charts/datetime_charts/all_chart.dart';
import 'package:sport_log/pages/workout/charts/datetime_charts/day_chart.dart';
import 'package:sport_log/pages/workout/charts/datetime_charts/month_chart.dart';
import 'package:sport_log/pages/workout/charts/datetime_charts/week_chart.dart';
import 'package:sport_log/pages/workout/charts/datetime_charts/year_chart.dart';
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
    return switch (this) {
      AggregatorType.min => list.minOrNull ?? 0,
      AggregatorType.max => list.maxOrNull ?? 0,
      AggregatorType.sum => list.sum,
      AggregatorType.avg => list.average,
      AggregatorType.none => list.first,
    };
  }
}

class DateTimeChart extends StatelessWidget {
  const DateTimeChart({
    required this.chartValues,
    required this.dateFilterState,
    required this.yFromZero,
    required this.aggregatorType,
    this.height = 200,
    super.key,
  });

  final List<DateTimeChartValue> chartValues;
  final DateFilterState dateFilterState;
  final bool yFromZero;
  final AggregatorType aggregatorType;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
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

    return switch (dateFilterState.runtimeType) {
      DayFilter => DayChart(
          chartValues: chartValues,
          yFromZero: yFromZero,
          isTime: false,
        ),
      WeekFilter => WeekChart(
          chartValues: chartValues,
          yFromZero: yFromZero,
          isTime: false,
          startDateTime: dateFilterState.start!,
        ),
      MonthFilter => MonthChart(
          chartValues: chartValues,
          yFromZero: yFromZero,
          isTime: false,
          startDateTime: dateFilterState.start!,
        ),
      YearFilter => YearChart(
          chartValues: chartValues,
          yFromZero: yFromZero,
          isTime: false,
          startDateTime: dateFilterState.start!,
        ),
      _ => AllChart(
          chartValues: chartValues,
          yFromZero: yFromZero,
          isTime: false,
        ),
    };
  }

  DateTime _groupFunction(DateTime dateTime) {
    return switch (dateFilterState.runtimeType) {
      DayFilter => dateTime,
      WeekFilter => dateTime.beginningOfDay(),
      MonthFilter => dateTime.beginningOfDay(),
      YearFilter => dateTime.beginningOfMonth().add(const Duration(days: 15)),
      _ => dateTime.beginningOfMonth().add(const Duration(days: 15)),
    };
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
    required Widget Function(double, TitleMeta) getBottomTitles,
    double? reservedSize,
  }) {
    return FlTitlesData(
      topTitles: const AxisTitles(),
      rightTitles: const AxisTitles(),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 1,
          getTitlesWidget: getBottomTitles,
          reservedSize: reservedSize ?? 22,
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: isTime ? 60 : 40,
          getTitlesWidget: (value, _) => Text(
            isTime ? Duration(milliseconds: value.round()).formatMsMill : "",
          ),
        ),
      ),
    );
  }
}
