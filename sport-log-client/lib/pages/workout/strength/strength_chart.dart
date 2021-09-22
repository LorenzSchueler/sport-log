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
    required this.dateFilter,
    required this.movement,
    required this.firstSessionDateTime,
  })  : availableSeries = getAvailableSeries(movement.unit),
        super(key: key);

  final DateFilterState dateFilter;
  final Movement movement;
  final List<SeriesType> availableSeries;
  final DateTime firstSessionDateTime;

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
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: _chart,
          ),
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
          date: widget.dateFilter.start!,
          movement: widget.movement,
        );
      case TimeFrame.week:
        return WeekChart(
            series: _activeSeriesType,
            start: widget.dateFilter.start!,
            movement: widget.movement);
      case TimeFrame.month:
        return MonthChart(
          series: _activeSeriesType,
          start: widget.dateFilter.start!,
          movement: widget.movement,
        );
      case TimeFrame.year:
        return YearChart(
          series: _activeSeriesType,
          start: widget.dateFilter.start!,
          movement: widget.movement,
        );
      case TimeFrame.all:
        return AllChart(
          series: _activeSeriesType,
          movement: widget.movement,
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
          child: Text(s.toDisplayName(widget.movement.unit)),
          style: selected
              ? OutlinedButton.styleFrom(
                  backgroundColor: primaryColorOf(context),
                  primary: onPrimaryColorOf(context),
                )
              : OutlinedButton.styleFrom(
                  side: BorderSide.none,
                ),
        );
      }).toList(),
    );
  }
}
