import 'package:flutter/material.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_state.dart';
import 'package:sport_log/pages/workout/strength_sessions/charts/all.dart';
import 'package:sport_log/pages/workout/strength_sessions/charts/series_type.dart';
import 'package:sport_log/widgets/input_fields/selection_bar.dart';

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
  late final availableSeries = getAvailableSeries(widget.movement.dimension);

  late SeriesType _activeSeriesType;

  @override
  void initState() {
    super.initState();
    _activeSeriesType = availableSeries.first;
    _logger
      ..i("movement: ${widget.movement.name}")
      ..i("date filter: ${widget.dateFilterState.name}");
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
                  setState(() => _activeSeriesType = type),
              items: availableSeries,
              getLabel: (SeriesType type) => type.toDisplayName(),
              selectedItem: _activeSeriesType,
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
    switch (widget.dateFilterState.runtimeType) {
      case DayFilter:
        return DayChart(
          series: _activeSeriesType,
          start: (widget.dateFilterState as DayFilter).start,
          movement: widget.movement,
        );
      case WeekFilter:
        return WeekChart(
          series: _activeSeriesType,
          start: (widget.dateFilterState as WeekFilter).start,
          movement: widget.movement,
        );
      case MonthFilter:
        return MonthChart(
          series: _activeSeriesType,
          start: (widget.dateFilterState as MonthFilter).start,
          movement: widget.movement,
        );
      case YearFilter:
        return YearChart(
          series: _activeSeriesType,
          start: (widget.dateFilterState as YearFilter).start,
          movement: widget.movement,
        );
      default:
        return AllChart(
          series: _activeSeriesType,
          movement: widget.movement,
        );
    }
  }
}
