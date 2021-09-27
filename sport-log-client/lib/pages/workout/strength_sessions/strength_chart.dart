import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_log/widgets/form_widgets/selection_bar.dart';

import 'charts/all.dart';
import 'charts/series_type.dart';
import '../date_filter/date_filter_state.dart';
import '../ui_cubit.dart';

class StrengthChart extends StatefulWidget {
  const StrengthChart({
    Key? key,
  }) : super(key: key);

  @override
  State<StrengthChart> createState() => _StrengthChartState();
}

class _StrengthChartState extends State<StrengthChart> {
  late SeriesType _activeSeriesType;

  @override
  void initState() {
    super.initState();
    final state = context.read<SessionsUiCubit>().state;
    assert(state.isMovementSelected);
    _activeSeriesType = getAvailableSeries(state.movement!.dimension).first;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionsUiCubit, SessionsUiState>(
      buildWhen: (oldState, newState) {
        return oldState.isStrengthPage &&
            (oldState.dateFilter != newState.dateFilter ||
                oldState.movement != newState.movement);
      },
      builder: (context, state) => Column(
        children: [
          _seriesSelection(state),
          AspectRatio(
            aspectRatio: 1.8,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 10, 20),
              child: _chart(state),
            ),
          ),
        ],
      ),
    );
  }

  void _setSeriesType(SeriesType type) {
    setState(() => _activeSeriesType = type);
  }

  Widget _chart(SessionsUiState state) {
    assert(state.isMovementSelected);
    if (state.dateFilter is DayFilter) {
      return DayChart(
        series: _activeSeriesType,
        date: (state.dateFilter as DayFilter).start,
        movement: state.movement!,
      );
    }
    if (state.dateFilter is WeekFilter) {
      return WeekChart(
          series: _activeSeriesType,
          start: (state.dateFilter as WeekFilter).start,
          movement: state.movement!);
    }
    if (state.dateFilter is MonthFilter) {
      return MonthChart(
        series: _activeSeriesType,
        start: (state.dateFilter as MonthFilter).start,
        movement: state.movement!,
      );
    }
    if (state.dateFilter is YearFilter) {
      return YearChart(
        series: _activeSeriesType,
        start: (state.dateFilter as YearFilter).start,
        movement: state.movement!,
      );
    }
    return AllChart(
      series: _activeSeriesType,
      movement: state.movement!,
    );
  }

  Widget _seriesSelection(SessionsUiState state) {
    assert(state.isMovementSelected);
    final availableSeries = getAvailableSeries(state.movement!.dimension);
    return SelectionBar(
      onChange: _setSeriesType,
      items: availableSeries,
      getLabel: (SeriesType type) =>
          type.toDisplayName(state.movement!.dimension),
      selectedItem: _activeSeriesType,
    );
  }
}
