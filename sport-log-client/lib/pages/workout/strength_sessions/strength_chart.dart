import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/strength_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/strength/strength_session_stats.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_state.dart';
import 'package:sport_log/pages/workout/charts/all.dart';
import 'package:sport_log/widgets/input_fields/selection_bar.dart';

enum SeriesType {
  maxDistance, // m
  minTime, // mSecs
  sumCalories, // cal
  maxEorm, // reps
  maxWeight, // reps
  maxReps, // reps
  avgReps, // reps
  sumVolume, // reps
}

extension on SeriesType {
  String toDisplayName() {
    switch (this) {
      case SeriesType.maxDistance:
        return 'Best Distance';
      case SeriesType.minTime:
        return 'Best Time';
      case SeriesType.sumCalories:
        return 'Total Calories';
      case SeriesType.maxEorm:
        return 'Eorm';
      case SeriesType.maxWeight:
        return 'Max Weight';
      case SeriesType.maxReps:
        return 'Max Reps';
      case SeriesType.avgReps:
        return 'Avg Reps';
      case SeriesType.sumVolume:
        return 'Total Volume';
    }
  }

  double statValue(StrengthSessionStats stats) {
    switch (this) {
      case SeriesType.maxDistance:
        return stats.maxCount.toDouble();
      case SeriesType.minTime:
        return stats.minCount.toDouble();
      case SeriesType.sumCalories:
        return stats.sumCount.toDouble();
      case SeriesType.maxEorm:
        return stats.maxEorm ?? 0;
      case SeriesType.maxWeight:
        return stats.maxWeight ?? 0;
      case SeriesType.maxReps:
        return stats.maxCount.toDouble();
      case SeriesType.avgReps:
        return stats.avgCount;
      case SeriesType.sumVolume:
        return stats.sumVolume ?? 0;
    }
  }
}

List<SeriesType> getAvailableSeries(MovementDimension dim) {
  switch (dim) {
    case MovementDimension.reps:
      return [
        SeriesType.maxEorm,
        SeriesType.maxWeight,
        SeriesType.maxReps,
        SeriesType.avgReps,
        SeriesType.sumVolume,
      ];
    case MovementDimension.energy:
      return [SeriesType.sumCalories];
    case MovementDimension.distance:
      return [SeriesType.maxDistance];
    case MovementDimension.time:
      return [SeriesType.minTime];
  }
}

class StrengthChart extends StatefulWidget {
  final Movement movement;
  final DateFilterState dateFilterState;

  const StrengthChart({
    Key? key,
    required this.movement,
    required this.dateFilterState,
  }) : super(key: key);

  @override
  State<StrengthChart> createState() => _StrengthChartState();
}

class _StrengthChartState extends State<StrengthChart> {
  final _logger = Logger('StrengthChart');
  final _dataProvider = StrengthSessionDescriptionDataProvider();
  late final availableSeries = getAvailableSeries(widget.movement.dimension);

  late SeriesType _selectedSeries;
  List<StrengthSessionStats> _strengthSessionStats = [];
  late Type _dataFilterType;

  @override
  void initState() {
    super.initState();
    _dataFilterType = widget.dateFilterState.runtimeType;
    _dataProvider.addListener(_update);
    _update();
    _selectedSeries = availableSeries.first;
    _logger
      ..i("movement: ${widget.movement.name}")
      ..i("date filter: ${widget.dateFilterState.name}");
  }

  @override
  void dispose() {
    _dataProvider.removeListener(_update);
    super.dispose();
  }

  @override
  void didUpdateWidget(StrengthChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ignore a change in series type
    if (oldWidget.movement != widget.movement ||
        oldWidget.dateFilterState.start != widget.dateFilterState.start ||
        oldWidget.dateFilterState.end != widget.dateFilterState.end) {
      _update();
    }
  }

  Future<void> _update() async {
    final List<StrengthSessionStats> strengthSessionStats;
    final Type dataFilterType;
    switch (widget.dateFilterState.runtimeType) {
      case DayFilter:
        strengthSessionStats = await _dataProvider.getStatsAggregationsBySet(
          movementId: widget.movement.id,
          date: (widget.dateFilterState as DayFilter).start,
        );
        dataFilterType = DayFilter;
        break;
      case WeekFilter:
        strengthSessionStats = await _dataProvider.getStatsAggregationsByDay(
          movementId: widget.movement.id,
          from: (widget.dateFilterState as WeekFilter).start,
          until: (widget.dateFilterState as WeekFilter).end,
        );
        dataFilterType = WeekFilter;
        break;
      case MonthFilter:
        strengthSessionStats = await _dataProvider.getStatsAggregationsByDay(
          movementId: widget.movement.id,
          from: (widget.dateFilterState as MonthFilter).start,
          until: (widget.dateFilterState as MonthFilter).end,
        );
        dataFilterType = MonthFilter;
        break;
      case YearFilter:
        strengthSessionStats = await _dataProvider.getStatsAggregationsByWeek(
          movementId: widget.movement.id,
          from: (widget.dateFilterState as YearFilter).start,
          until: (widget.dateFilterState as YearFilter).end,
        );
        dataFilterType = YearFilter;
        break;
      default:
        strengthSessionStats = await _dataProvider.getStatsAggregationsByMonth(
          movementId: widget.movement.id,
        );
        dataFilterType = NoFilter;
        break;
    }
    if (mounted) {
      setState(() {
        _strengthSessionStats = strengthSessionStats;
        _dataFilterType = dataFilterType;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Scrollbar(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SelectionBar(
              onChange: (SeriesType type) =>
                  setState(() => _selectedSeries = type),
              items: availableSeries,
              getLabel: (SeriesType type) => type.toDisplayName(),
              selectedItem: _selectedSeries,
            ),
          ),
        ),
        Defaults.sizedBox.vertical.small,
        AspectRatio(
          aspectRatio: 1.8,
          child: _chart(),
        ),
      ],
    );
  }

  Widget _chart() {
    // use _dataFilterType instead of widget.dateFilterState.runtimeType to keep data in sync with chart type even if update not yet computed
    switch (_dataFilterType) {
      case DayFilter:
        return DayChart(
          chartValues: _strengthSessionStats
              .map(
                (s) => ChartValue(s.datetime, _selectedSeries.statValue(s)),
              )
              .toList(),
          isTime: widget.movement.dimension == MovementDimension.time,
        );
      case WeekFilter:
        return WeekChart(
          chartValues: _strengthSessionStats
              .map(
                (s) => ChartValue(s.datetime, _selectedSeries.statValue(s)),
              )
              .toList(),
          isTime: widget.movement.dimension == MovementDimension.time,
        );
      case MonthFilter:
        return MonthChart(
          chartValues: _strengthSessionStats
              .map(
                (s) => ChartValue(s.datetime, _selectedSeries.statValue(s)),
              )
              .toList(),
          isTime: widget.movement.dimension == MovementDimension.time,
        );
      case YearFilter:
        return YearChart(
          chartValues: _strengthSessionStats
              .map(
                (s) => ChartValue(s.datetime, _selectedSeries.statValue(s)),
              )
              .toList(),
          isTime: widget.movement.dimension == MovementDimension.time,
        );
      default:
        return AllChart(
          chartValues: _strengthSessionStats
              .map(
                (s) => ChartValue(s.datetime, _selectedSeries.statValue(s)),
              )
              .toList(),
          isTime: widget.movement.dimension == MovementDimension.time,
        );
    }
  }
}
