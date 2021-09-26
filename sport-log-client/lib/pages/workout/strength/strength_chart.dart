import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_state.dart';
import 'package:sport_log/pages/workout/strength/charts/all.dart';
import 'package:sport_log/widgets/form_widgets/selection_bar.dart';

import 'charts/series_type.dart';

class StrengthChart extends StatefulWidget {
  StrengthChart({
    Key? key,
    required this.dateFilter,
    required this.movement,
  })  : availableSeries = getAvailableSeries(movement.dimension),
        super(key: key);

  final DateFilterState dateFilter;
  final Movement movement;
  final List<SeriesType> availableSeries;

  @override
  State<StrengthChart> createState() => _StrengthChartState();
}

class _StrengthChartState extends State<StrengthChart> {
  @override
  void didUpdateWidget(StrengthChart oldWidget) {
    if (oldWidget.movement.id != widget.movement.id) {
      setState(() {
        _activeSeriesType = widget.availableSeries.first;
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _seriesSelection,
        AspectRatio(
          aspectRatio: 1.8,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 10, 20),
            child: _chart,
          ),
        ),
      ],
    );
  }

  late SeriesType _activeSeriesType;

  void _setSeriesType(SeriesType type) {
    setState(() => _activeSeriesType = type);
  }

  @override
  void initState() {
    super.initState();
    _activeSeriesType = widget.availableSeries.first;
  }

  Widget get _chart {
    if (widget.dateFilter is DayFilter) {
      return DayChart(
        series: _activeSeriesType,
        date: (widget.dateFilter as DayFilter).start,
        movement: widget.movement,
      );
    }
    if (widget.dateFilter is WeekFilter) {
      return WeekChart(
          series: _activeSeriesType,
          start: (widget.dateFilter as WeekFilter).start,
          movement: widget.movement);
    }
    if (widget.dateFilter is MonthFilter) {
      return MonthChart(
        series: _activeSeriesType,
        start: (widget.dateFilter as MonthFilter).start,
        movement: widget.movement,
      );
    }
    if (widget.dateFilter is YearFilter) {
      return YearChart(
        series: _activeSeriesType,
        start: (widget.dateFilter as YearFilter).start,
        movement: widget.movement,
      );
    }
    return AllChart(
      series: _activeSeriesType,
      movement: widget.movement,
    );
  }

  Widget get _seriesSelection {
    return SelectionBar(
      onChange: _setSeriesType,
      items: widget.availableSeries,
      getLabel: (SeriesType type) => type.toDisplayName(widget.movement.dimension),
      selectedItem: _activeSeriesType,
    );
  }
}
