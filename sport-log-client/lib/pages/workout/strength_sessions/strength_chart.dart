import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/strength/strength_session_description.dart';
import 'package:sport_log/models/strength/strength_session_stats.dart';
import 'package:sport_log/pages/workout/charts/datetime_chart.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_state.dart';
import 'package:sport_log/widgets/input_fields/selection_bar.dart';

enum _SeriesType {
  maxDistance, // m
  minTime, // mSecs
  sumCalories, // cal
  maxEorm, // reps
  maxWeight, // reps
  maxReps, // reps
  avgReps, // reps
  sumVolume; // reps

  @override
  String toString() {
    switch (this) {
      case _SeriesType.maxDistance:
        return 'Best Distance';
      case _SeriesType.minTime:
        return 'Best Time';
      case _SeriesType.sumCalories:
        return 'Total Calories';
      case _SeriesType.maxEorm:
        return 'Eorm';
      case _SeriesType.maxWeight:
        return 'Max Weight';
      case _SeriesType.maxReps:
        return 'Max Reps';
      case _SeriesType.avgReps:
        return 'Avg Reps';
      case _SeriesType.sumVolume:
        return 'Total Volume';
    }
  }

  double? value(StrengthSessionStats stats) {
    switch (this) {
      case _SeriesType.maxDistance:
        return stats.maxCount.toDouble();
      case _SeriesType.minTime:
        return stats.minCount.toDouble();
      case _SeriesType.sumCalories:
        return stats.sumCount.toDouble();
      case _SeriesType.maxEorm:
        return stats.maxEorm;
      case _SeriesType.maxWeight:
        return stats.maxWeight;
      case _SeriesType.maxReps:
        return stats.maxCount.toDouble();
      case _SeriesType.avgReps:
        return stats.avgCount;
      case _SeriesType.sumVolume:
        return stats.sumVolume;
    }
  }

  AggregatorType aggregator() {
    switch (this) {
      case _SeriesType.maxDistance:
        return AggregatorType.max;
      case _SeriesType.minTime:
        return AggregatorType.min;
      case _SeriesType.sumCalories:
        return AggregatorType.sum;
      case _SeriesType.maxEorm:
        return AggregatorType.max;
      case _SeriesType.maxWeight:
        return AggregatorType.max;
      case _SeriesType.maxReps:
        return AggregatorType.max;
      case _SeriesType.avgReps:
        return AggregatorType.avg;
      case _SeriesType.sumVolume:
        return AggregatorType.sum;
    }
  }

  bool isYFromZero() => [
        _SeriesType.maxDistance,
        _SeriesType.maxReps,
        _SeriesType.avgReps,
        _SeriesType.sumVolume
      ].contains(this);
}

List<_SeriesType> _getAvailableSeries(MovementDimension dim) {
  switch (dim) {
    case MovementDimension.reps:
      return [
        _SeriesType.maxEorm,
        _SeriesType.maxWeight,
        _SeriesType.maxReps,
        _SeriesType.avgReps,
        _SeriesType.sumVolume,
      ];
    case MovementDimension.energy:
      return [_SeriesType.sumCalories];
    case MovementDimension.distance:
      return [_SeriesType.maxDistance];
    case MovementDimension.time:
      return [_SeriesType.minTime];
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
  final _logger = Logger('StrengthChart');
  late final availableSeries = _getAvailableSeries(movementDimension);
  MovementDimension get movementDimension =>
      widget.strengthSessionDescriptions.first.movement.dimension;
  bool get isTime => movementDimension == MovementDimension.time;

  late _SeriesType _selectedSeries = availableSeries.first;
  late List<StrengthSessionStats> _strengthSessionStats;

  @override
  void initState() {
    calculateStats();
    _logger.i("date filter: ${widget.dateFilterState.name}");
    super.initState();
  }

  @override
  void didUpdateWidget(covariant StrengthChart oldWidget) {
    calculateStats();
    super.didUpdateWidget(oldWidget);
  }

  void calculateStats() {
    _strengthSessionStats = widget.strengthSessionDescriptions
        .map(
          (e) => StrengthSessionStats.fromStrengthSets(
            e.session.datetime,
            movementDimension,
            e.sets,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Scrollbar(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SelectionBar(
              onChange: (_SeriesType type) =>
                  setState(() => _selectedSeries = type),
              items: availableSeries,
              getLabel: (_SeriesType type) => type.toString(),
              selectedItem: _selectedSeries,
            ),
          ),
        ),
        Defaults.sizedBox.vertical.small,
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
          yFromZero: _selectedSeries.isYFromZero(),
          aggregatorType: _selectedSeries.aggregator(),
        ),
      ],
    );
  }
}
