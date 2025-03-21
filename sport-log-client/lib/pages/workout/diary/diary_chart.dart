import 'package:flutter/material.dart';
import 'package:sport_log/models/diary/diary.dart';
import 'package:sport_log/pages/workout/charts/datetime_chart.dart';
import 'package:sport_log/pages/workout/date_filter/date_filter_state.dart';

class DiaryChart extends StatelessWidget {
  const DiaryChart({
    required this.diaries,
    required this.dateFilterState,
    super.key,
  });

  final List<Diary> diaries;
  final DateFilterState dateFilterState;

  @override
  Widget build(BuildContext context) {
    return DateTimeChart(
      chartValues:
          diaries
              .map((s) {
                final value = s.bodyweight;
                return value == null
                    ? null
                    : DateTimeChartValue(datetime: s.date, value: value);
              })
              .nonNulls
              .toList(),
      dateFilterState: dateFilterState,
      absolute: false,
      formatter: ChartValueFormatter.float,
      aggregatorType: AggregatorType.avg,
    );
  }
}
