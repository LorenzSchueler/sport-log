import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:sport_log/helpers/theme.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/pages/workout/date_filter_state.dart';
import 'package:sport_log/pages/workout/strength/charts/all.dart';

import 'charts/series_type.dart';

class StrengthChart extends StatefulWidget {
  StrengthChart({
    Key? key,
    required this.unit,
    required this.dateFilter,
    required this.movement,
    required this.firstSessionDateTime,
  })  : availableSeries = getAvailableSeries(unit),
        super(key: key);

  final MovementUnit unit;
  final DateFilterState dateFilter;
  final Movement movement;
  final List<SeriesType> availableSeries;
  final DateTime firstSessionDateTime;

  @override
  State<StrengthChart> createState() => _StrengthChartState();
}

class _StrengthChartState extends State<StrengthChart> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _seriesSelection,
        AspectRatio(
          aspectRatio: 2,
          child: _chart,
        ),
      ],
    );
  }

  late SeriesType _activeSeriesType;

  @override
  void initState() {
    super.initState();
    _activeSeriesType = widget.availableSeries.first;
  }

  Widget get _chart {
    switch (widget.dateFilter.timeFrame) {
      case TimeFrame.day:
        return DayChart(
          series: _activeSeriesType,
          unit: widget.unit,
          date: widget.dateFilter.start!,
          movementId: widget.movement.id,
        );
      case TimeFrame.week:
        return WeekChart(
            series: _activeSeriesType,
            unit: widget.unit,
            start: widget.dateFilter.start!,
            movementId: widget.movement.id);
      case TimeFrame.month:
        return MonthChart(
          series: _activeSeriesType,
          unit: widget.unit,
          start: widget.dateFilter.start!,
          movementId: widget.movement.id,
        );
      case TimeFrame.year:
        return YearChart(
          series: _activeSeriesType,
          unit: widget.unit,
          start: widget.dateFilter.start!,
          movementId: widget.movement.id,
        );
      case TimeFrame.all:
        return AllChart(
          series: _activeSeriesType,
          unit: widget.unit,
          movementId: widget.movement.id,
          firstDateTime: widget.firstSessionDateTime,
        );
    }
  }

  Widget get _seriesSelection {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: widget.availableSeries.map((s) {
        final selected = s == _activeSeriesType;
        return OutlinedButton(
          onPressed: () {
            setState(() => _activeSeriesType = s);
          },
          child: Text(s.toDisplayName(widget.unit)),
          style: selected ? OutlinedButton.styleFrom(
            backgroundColor: primaryColorOf(context),
            primary: onPrimaryColorOf(context),
          ) : OutlinedButton.styleFrom(
            side: BorderSide.none,
          ),
        );
      }).toList(),
    );
  }
}
