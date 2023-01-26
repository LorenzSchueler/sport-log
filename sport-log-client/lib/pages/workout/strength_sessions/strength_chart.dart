import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/strength/strength_session_description.dart';
import 'package:sport_log/models/strength/strength_session_stats.dart';
import 'package:sport_log/pages/workout/charts/datetime_chart.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_state.dart';

enum _SeriesType {
  maxWeight('Max Weight', AggregatorType.max, false), // kg
  avgWeight('Avg Weight', AggregatorType.avg, false), // kg
  maxDistance('Max Distance', AggregatorType.max, true), // m
  minTime('Best Time', AggregatorType.min, false), // mSecs
  sumCalories('Total Calories', AggregatorType.sum, false), // cal
  maxReps('Max Reps', AggregatorType.max, true), // reps
  avgReps('Avg Reps', AggregatorType.avg, true), // reps
  maxEorm('Eorm', AggregatorType.max, false), // kg
  sumVolume('Total Volume', AggregatorType.sum, true); // kg

  const _SeriesType(this.name, this.aggregator, this.yFromZero);

  final String name;
  final AggregatorType aggregator;
  final bool yFromZero;

  double? value(StrengthSessionStats stats) {
    switch (this) {
      case _SeriesType.maxWeight:
        return stats.maxWeight;
      case _SeriesType.avgWeight:
        return stats.avgWeight;
      case _SeriesType.maxDistance:
        return stats.maxCount.toDouble();
      case _SeriesType.minTime:
        return stats.minCount.toDouble();
      case _SeriesType.sumCalories:
        return stats.sumCount.toDouble();
      case _SeriesType.maxEorm:
        return stats.maxEorm;
      case _SeriesType.maxReps:
        return stats.maxCount.toDouble();
      case _SeriesType.avgReps:
        return stats.avgCount;
      case _SeriesType.sumVolume:
        return stats.sumVolume;
    }
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
    switch (widget.strengthSessionDescriptions.first.movement.dimension) {
      case MovementDimension.reps:
        return [
          _SeriesType.maxEorm,
          _SeriesType.maxWeight,
          _SeriesType.avgWeight,
          _SeriesType.maxReps,
          _SeriesType.avgReps,
          _SeriesType.sumVolume,
        ];
      case MovementDimension.energy:
        return [
          _SeriesType.sumCalories,
          _SeriesType.maxWeight,
          _SeriesType.avgWeight,
        ];
      case MovementDimension.distance:
        return [
          _SeriesType.maxDistance,
          _SeriesType.maxWeight,
          _SeriesType.avgWeight,
        ];
      case MovementDimension.time:
        return [
          _SeriesType.minTime,
          _SeriesType.maxWeight,
          _SeriesType.avgWeight,
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Scrollbar(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<_SeriesType>(
              segments: _availableSeries
                  .map(
                    (md) => ButtonSegment(
                      value: md,
                      label: Text(md.name),
                    ),
                  )
                  .toList(),
              selected: {_selectedSeries},
              onSelectionChanged: (selected) =>
                  setState(() => _selectedSeries = selected.first),
            ),
          ),
        ),
        Defaults.sizedBox.vertical.normal,
        DateTimeChart(
          chartValues: _strengthSessionStats
              .map((s) {
                final value = _selectedSeries.value(s);
                return value == null
                    ? null
                    : DateTimeChartValue(datetime: s.datetime, value: value);
              })
              .whereNotNull()
              .toList(),
          dateFilterState: widget.dateFilterState,
          yFromZero: _selectedSeries.yFromZero,
          aggregatorType: _selectedSeries.aggregator,
        ),
      ],
    );
  }
}
