import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_state.dart';

class DateTimeChartValue {
  DateTimeChartValue({required this.datetime, required this.value});

  final DateTime datetime;
  final double value;

  @override
  String toString() => "$datetime: $value";
}

enum ChartValueFormatter {
  float,
  hms,
  ms,
  msMilli;

  double get width => switch (this) {
        ChartValueFormatter.float => 40.0,
        ChartValueFormatter.hms => 60.0,
        ChartValueFormatter.ms => 40.0,
        ChartValueFormatter.msMilli => 70.0,
      };

  Widget text(double value, TitleMeta meta) => switch (this) {
        ChartValueFormatter.float => defaultGetTitle(value, meta),
        ChartValueFormatter.hms =>
          Text(Duration(milliseconds: value.round()).formatHms),
        ChartValueFormatter.ms =>
          Text(Duration(milliseconds: value.round()).formatM99S),
        ChartValueFormatter.msMilli =>
          Text(Duration(milliseconds: value.round()).formatMsMill),
      };
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
    required this.absolute,
    required this.formatter,
    required this.aggregatorType,
    this.height = 200,
    super.key,
  });

  final List<DateTimeChartValue> chartValues;
  final DateFilterState dateFilterState;
  final bool absolute;
  final ChartValueFormatter formatter;
  final AggregatorType aggregatorType;
  final double height;

  @override
  Widget build(BuildContext context) {
    final chartValues = this
        .chartValues
        .groupListsBy((v) => dateFilterState.groupFunction(v.datetime))
        .entries
        .map(
          (entry) => DateTimeChartValue(
            datetime: entry.key,
            value: aggregatorType.compute(entry.value.map((e) => e.value)),
          ),
        )
        .toList()
      ..sort((v1, v2) => v1.datetime.compareTo(v2.datetime));

    return SizedBox(
      height: height,
      child: dateFilterState.chart(chartValues, absolute, formatter),
    );
  }
}

abstract class DateTimePeriodChart extends StatelessWidget {
  DateTimePeriodChart({
    required this.chartValues,
    required this.absolute,
    required this.formatter,
    super.key,
  })  : _maxY =
            (chartValues.map((v) => v.value).maxOrNull ?? 0).ceil().toDouble(),
        _minY = absolute
            ? 0.0
            : (chartValues.map((v) => v.value).minOrNull ?? 0)
                .floor()
                .toDouble();

  final List<DateTimeChartValue> chartValues;
  final ChartValueFormatter formatter;
  final bool absolute;
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
          reservedSize: formatter.width,
          getTitlesWidget: formatter.text,
        ),
      ),
    );
  }
}
