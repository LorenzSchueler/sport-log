import 'package:flutter/material.dart';
import 'package:sport_log/models/diary/diary.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_state.dart';
import 'package:sport_log/pages/workout/charts/all.dart';

class DiaryChart extends StatelessWidget {
  const DiaryChart({
    Key? key,
    required this.diaries,
    required this.dateFilterState,
  }) : super(key: key);

  final DateFilterState dateFilterState;
  final List<Diary> diaries;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.8,
      child: _chart(),
    );
  }

  Widget _chart() {
    final chartValues = diaries
        .map((s) => ChartValue(s.date, s.bodyweight ?? 0))
        .toList()
        .reversed // data must be ordered asc datetime
        .toList();
    switch (dateFilterState.runtimeType) {
      case DayFilter:
        return DayChart(
          chartValues: chartValues,
          isTime: false,
        );
      case WeekFilter:
        return WeekChart(
          chartValues: chartValues,
          isTime: false,
        );
      case MonthFilter:
        return MonthChart(
          chartValues: chartValues,
          isTime: false,
        );
      case YearFilter:
        return YearChart(
          chartValues: chartValues,
          isTime: false,
        );
      default:
        return AllChart(
          chartValues: chartValues,
          isTime: false,
        );
    }
  }
}
