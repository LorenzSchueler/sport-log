import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_widget.dart';
import 'package:sport_log/widgets/form_widgets/selection_bar.dart';

import 'charts/all.dart';
import 'charts/series_type.dart';
import '../date_filter/date_filter_state.dart';

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
  final _logger = Logger('RoutePage');

  late SeriesType _activeSeriesType;

  @override
  void initState() {
    super.initState();
    _activeSeriesType = getAvailableSeries(widget.movement.dimension).first;
    _logger.i(widget.movement);
    _logger.i(widget.dateFilterState);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _seriesSelection(),
        AspectRatio(
          aspectRatio: 1.8,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 10, 20),
            child: _chart(),
          ),
        ),
      ],
    );
  }

  void _setSeriesType(SeriesType type) {
    setState(() => _activeSeriesType = type);
  }

  Widget _chart() {
    if (widget.dateFilterState is DayFilter) {
      return DayChart(
        series: _activeSeriesType,
        date: (widget.dateFilterState as DayFilter).start,
        movement: widget.movement,
      );
    }
    if (widget.dateFilterState is WeekFilter) {
      return WeekChart(
          series: _activeSeriesType,
          start: (widget.dateFilterState as WeekFilter).start,
          movement: widget.movement);
    }
    if (widget.dateFilterState is MonthFilter) {
      return MonthChart(
        series: _activeSeriesType,
        start: (widget.dateFilterState as MonthFilter).start,
        movement: widget.movement,
      );
    }
    if (widget.dateFilterState is YearFilter) {
      return YearChart(
        series: _activeSeriesType,
        start: (widget.dateFilterState as YearFilter).start,
        movement: widget.movement,
      );
    }
    return AllChart(
      series: _activeSeriesType,
      movement: widget.movement,
    );
  }

  Widget _seriesSelection() {
    final availableSeries = getAvailableSeries(widget.movement.dimension);
    return SelectionBar(
      onChange: _setSeriesType,
      items: availableSeries,
      getLabel: (SeriesType type) =>
          type.toDisplayName(widget.movement.dimension),
      selectedItem: _activeSeriesType,
    );
  }
}
