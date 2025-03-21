import 'package:flutter/material.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/strength/strength_session_description.dart';
import 'package:sport_log/models/strength/strength_session_stats.dart';
import 'package:sport_log/pages/workout/charts/datetime_chart.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_state.dart';

enum _SeriesType {
  maxWeight(
    'Max Weight',
    AggregatorType.max,
    ChartValueFormatter.float,
    false,
  ), // kg
  avgWeight(
    'Avg Weight',
    AggregatorType.avg,
    ChartValueFormatter.float,
    false,
  ), // kg
  maxDistance(
    'Max Distance',
    AggregatorType.max,
    ChartValueFormatter.float,
    true,
  ), // m
  minTime(
    'Best Time',
    AggregatorType.min,
    ChartValueFormatter.msMilli,
    false,
  ), // ms
  sumCalories(
    'Total Calories',
    AggregatorType.sum,
    ChartValueFormatter.float,
    false,
  ), // cal
  maxReps(
    'Max Reps',
    AggregatorType.max,
    ChartValueFormatter.float,
    true,
  ), // reps
  avgReps(
    'Avg Reps',
    AggregatorType.avg,
    ChartValueFormatter.float,
    true,
  ), // reps
  maxEorm('Eorm', AggregatorType.max, ChartValueFormatter.float, false), // kg
  sumVolume(
    'Total Volume',
    AggregatorType.sum,
    ChartValueFormatter.float,
    true,
  ); // kg

  const _SeriesType(this.name, this.aggregator, this.formatter, this.yFromZero);

  final String name;
  final AggregatorType aggregator;
  final ChartValueFormatter formatter;
  final bool yFromZero;

  double? value(StrengthSessionStats stats) {
    return switch (this) {
      _SeriesType.maxWeight => stats.maxWeight,
      _SeriesType.avgWeight => stats.avgWeight,
      _SeriesType.maxDistance => stats.maxCount.toDouble(),
      _SeriesType.minTime => stats.minCount.toDouble(),
      _SeriesType.sumCalories => stats.sumCount.toDouble(),
      _SeriesType.maxEorm => stats.maxEorm,
      _SeriesType.maxReps => stats.maxCount.toDouble(),
      _SeriesType.avgReps => stats.avgCount,
      _SeriesType.sumVolume => stats.sumVolume,
    };
  }
}

class StrengthChart extends StatefulWidget {
  const StrengthChart({
    required this.strengthSessionDescriptions,
    required this.dateFilterState,
    super.key,
  });

  final List<StrengthSessionDescription> strengthSessionDescriptions;
  final DateFilterState dateFilterState;

  @override
  State<StrengthChart> createState() => _StrengthChartState();
}

class _StrengthChartState extends State<StrengthChart> {
  late List<StrengthSessionStats> _strengthSessionStats = calculateStats();
  late List<_SeriesType> _availableSeries = _getAvailableSeries();
  late _SeriesType _selectedSeries = _availableSeries.first;

  @override
  void didUpdateWidget(StrengthChart oldWidget) {
    _strengthSessionStats = calculateStats();
    _availableSeries = _getAvailableSeries();
    _selectedSeries = _availableSeries.first;
    super.didUpdateWidget(oldWidget);
  }

  List<StrengthSessionStats> calculateStats() =>
      widget.strengthSessionDescriptions.map((d) => d.stats).toList();

  List<_SeriesType> _getAvailableSeries() {
    return switch (widget
        .strengthSessionDescriptions
        .first
        .movement
        .dimension) {
      MovementDimension.reps => [
        _SeriesType.maxEorm,
        _SeriesType.maxWeight,
        _SeriesType.avgWeight,
        _SeriesType.maxReps,
        _SeriesType.avgReps,
        _SeriesType.sumVolume,
      ],
      MovementDimension.energy => [
        _SeriesType.sumCalories,
        _SeriesType.maxWeight,
        _SeriesType.avgWeight,
      ],
      MovementDimension.distance => [
        _SeriesType.maxDistance,
        _SeriesType.maxWeight,
        _SeriesType.avgWeight,
      ],
      MovementDimension.time => [
        _SeriesType.minTime,
        _SeriesType.maxWeight,
        _SeriesType.avgWeight,
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Scrollbar(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton(
              segments:
                  _availableSeries
                      .map(
                        (md) => ButtonSegment(value: md, label: Text(md.name)),
                      )
                      .toList(),
              selected: {_selectedSeries},
              showSelectedIcon: false,
              onSelectionChanged:
                  (selected) =>
                      setState(() => _selectedSeries = selected.first),
            ),
          ),
        ),
        Defaults.sizedBox.vertical.normal,
        DateTimeChart(
          chartValues:
              _strengthSessionStats
                  .map((s) {
                    final value = _selectedSeries.value(s);
                    return value == null
                        ? null
                        : DateTimeChartValue(
                          datetime: s.datetime,
                          value: value,
                        );
                  })
                  .nonNulls
                  .toList(),
          dateFilterState: widget.dateFilterState,
          absolute: _selectedSeries.yFromZero,
          formatter: _selectedSeries.formatter,
          aggregatorType: _selectedSeries.aggregator,
        ),
      ],
    );
  }
}
