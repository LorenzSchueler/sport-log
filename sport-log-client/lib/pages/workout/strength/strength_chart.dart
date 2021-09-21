import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/data_providers/strength_data_provider.dart';
import 'package:sport_log/helpers/snackbar.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/strength/strength_session_description.dart';
import 'package:sport_log/pages/workout/date_filter_state.dart';

enum SeriesType {
  maxCount, // m
  minCount, // mSecs
  sumCount, // cal
  avgCount, // reps (maybe even with maxWeight)
  maxEorm, // reps
  sumVolume, // reps
  maxWeight, // reps
}

class StrengthChart extends StatefulWidget {
  StrengthChart({
    Key? key,
    required this.sessions,
    required this.dateFilter,
    required this.movement,
  })  : assert(sessions.isNotEmpty),
        super(key: key) {
    final movementUnit = sessions.first.strengthSession.movementUnit;
    switch (movementUnit) {
      // TODO: add MovementUni.mSecs
      case MovementUnit.reps:
        availableSeries = [
          SeriesType.avgCount,
          SeriesType.maxEorm,
          SeriesType.sumVolume,
          SeriesType.maxWeight
        ];
        break;
      case MovementUnit.cal:
        availableSeries = [SeriesType.sumCount];
        break;
      case MovementUnit.meter:
        availableSeries = [SeriesType.maxCount];
        break;
      case MovementUnit.km:
        throw StateError('MovementUnit.km cannot be in a strength session.');
      case MovementUnit.yard:
        throw StateError('MovementUnit.yard cannot be in a strength session.');
      case MovementUnit.foot:
        throw StateError('MovementUnit.foot cannot be in a strength session.');
      case MovementUnit.mile:
        throw StateError('MovementUnit.foot cannot be in a strength session.');
    }
  }

  final List<StrengthSessionDescription> sessions;
  final DateFilterState dateFilter;
  final Movement movement;
  late final List<SeriesType> availableSeries;

  @override
  State<StrengthChart> createState() => _StrengthChartState();
}

class _StrengthChartState extends State<StrengthChart> {
  @override
  Widget build(BuildContext context) {
    return _chart;
  }

  final _dataProvider = StrengthDataProvider();
  late SeriesType _activeSeriesType;

  @override
  void initState() {
    _activeSeriesType = widget.availableSeries.first;
    super.initState();
  }

  Widget get _chart {
    switch (widget.dateFilter.timeFrame) {
      case TimeFrame.day:
        return _dayChart;
      case TimeFrame.week:
        return _weekChart;
      case TimeFrame.month:
        return _monthChart;
      case TimeFrame.year:
        return _yearChart;
      case TimeFrame.all:
        return _allChart;
    }
  }

  Widget get _dayChart {
    return FutureBuilder(
      future: _dataProvider.populateWithSets(widget.sessions),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
          case ConnectionState.active:
            return const CircularProgressIndicator();
          case ConnectionState.done:
            if (snapshot.hasError) {
              Future(
                  () => showSimpleSnackBar(context, 'Something went wrong.'));
              return Container();
            } else {
              return DayChart(
                  sessions: widget.sessions, series: _activeSeriesType);
            }
        }
      },
    );
  }

  Widget get _weekChart {
    return notImplemented;
  }

  Widget get _monthChart {
    return notImplemented;
  }

  Widget get _yearChart {
    return notImplemented;
  }

  Widget get _allChart {
    return notImplemented;
  }

  final Widget notImplemented = const Center(child: Text('not implemented'));
}

class DayChart extends StatelessWidget {
  DayChart({Key? key, required this.sessions, required this.series})
      : assert(sessions.every((session) => session.strengthSets != null)),
        super(key: key);

  final List<StrengthSessionDescription> sessions; // these have to be with sets
  final SeriesType series;

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class WeekChart extends StatelessWidget {
  const WeekChart({Key? key, required this.sessions, required this.series})
      : super(key: key);

  final List<StrengthSessionDescription> sessions;
  final SeriesType series;

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class MonthChart extends StatelessWidget {
  const MonthChart({Key? key, required this.sessions, required this.series})
      : super(key: key);

  final List<StrengthSessionDescription> sessions;
  final SeriesType series;

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class YearChart extends StatelessWidget {
  const YearChart({Key? key, required this.sessions, required this.series})
      : super(key: key);

  final List<StrengthSessionDescription> sessions;
  final SeriesType series;

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class AllChart extends StatelessWidget {
  const AllChart({Key? key, required this.sessions, required this.series})
      : super(key: key);

  final List<StrengthSessionDescription> sessions;
  final SeriesType series;

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
