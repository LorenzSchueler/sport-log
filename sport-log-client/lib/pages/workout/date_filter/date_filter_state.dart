import 'package:flutter/widgets.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/pages/workout/charts/datetime_chart.dart';
import 'package:sport_log/pages/workout/charts/datetime_charts/all_chart.dart';
import 'package:sport_log/pages/workout/charts/datetime_charts/day_chart.dart';
import 'package:sport_log/pages/workout/charts/datetime_charts/month_chart.dart';
import 'package:sport_log/pages/workout/charts/datetime_charts/week_chart.dart';
import 'package:sport_log/pages/workout/charts/datetime_charts/year_chart.dart';

sealed class DateFilterState {
  const DateFilterState();

  DateTime? get start;

  DateTime get end;

  DateTime groupFunction(DateTime datetime);

  bool get goingForwardPossible => end.isBefore(DateTime.now());

  DateFilterState get earlier;

  DateFilterState get later;

  /// returns String with human readable formatted date
  String get label;

  /// return static String with name of filter
  String get name;

  Widget chart(
    List<DateTimeChartValue> chartValues,
    bool absolute,
    ChartValueFormatter formatter,
  );

  @override
  int get hashCode => Object.hash(runtimeType, start, end);

  @override
  bool operator ==(Object other) =>
      other is DateFilterState && other.start == start && other.end == end;

  static List<DateFilterState> all(DateFilterState dateFilterState) {
    final now = DateTime.now();
    final inclusiveEnd = dateFilterState.end.subtract(const Duration(days: 1));
    final end = now.compareTo(inclusiveEnd) < 0 ? now : inclusiveEnd;
    return [
      DayFilter(end),
      WeekFilter(end),
      MonthFilter(end),
      YearFilter(end),
      const AllFilter(),
    ];
  }

  static DateFilterState get init => MonthFilter(DateTime.now());
}

class DayFilter extends DateFilterState {
  factory DayFilter(DateTime date) {
    return DayFilter._(date.beginningOfDay());
  }

  const DayFilter._(this.start);

  @override
  final DateTime start;

  @override
  DateTime get end => start.dayLater();

  @override
  DateTime groupFunction(DateTime datetime) => datetime;

  @override
  DayFilter get earlier => DayFilter._(start.dayEarlier());

  @override
  DayFilter get later => DayFilter._(end);

  @override
  String get label => start.humanDate;

  @override
  final String name = 'Day';

  @override
  Widget chart(
    List<DateTimeChartValue> chartValues,
    bool absolute,
    ChartValueFormatter formatter,
  ) {
    return DayChart(
      chartValues: chartValues,
      absolute: absolute,
      formatter: formatter,
    );
  }
}

class WeekFilter extends DateFilterState {
  factory WeekFilter(DateTime date) {
    return WeekFilter._(date.beginningOfWeek());
  }

  const WeekFilter._(this.start);

  @override
  final DateTime start;

  @override
  DateTime get end => start.weekLater();

  @override
  DateTime groupFunction(DateTime datetime) => datetime.beginningOfDay();

  @override
  WeekFilter get earlier => WeekFilter._(start.weekEarlier());

  @override
  WeekFilter get later => WeekFilter._(end);

  @override
  String get label => start.humanWeek;

  @override
  final String name = 'Week';

  @override
  Widget chart(
    List<DateTimeChartValue> chartValues,
    bool absolute,
    ChartValueFormatter formatter,
  ) {
    return WeekChart(
      chartValues: chartValues,
      absolute: absolute,
      formatter: formatter,
      startDateTime: start,
    );
  }
}

class MonthFilter extends DateFilterState {
  factory MonthFilter(DateTime date) {
    return MonthFilter._(date.beginningOfMonth());
  }

  const MonthFilter._(this.start);

  @override
  final DateTime start;

  @override
  DateTime get end => start.monthLater();

  @override
  DateTime groupFunction(DateTime datetime) => datetime.beginningOfDay();

  @override
  MonthFilter get earlier => MonthFilter._(start.monthEarlier());

  @override
  MonthFilter get later => MonthFilter._(end);

  @override
  String get label => start.humanMonth;

  @override
  final String name = 'Month';

  @override
  Widget chart(
    List<DateTimeChartValue> chartValues,
    bool absolute,
    ChartValueFormatter formatter,
  ) {
    return MonthChart(
      chartValues: chartValues,
      absolute: absolute,
      formatter: formatter,
      startDateTime: start,
    );
  }
}

class YearFilter extends DateFilterState {
  factory YearFilter(DateTime date) {
    return YearFilter._(date.beginningOfYear());
  }

  const YearFilter._(this.start);

  @override
  final DateTime start;

  @override
  DateTime get end => start.yearLater();

  @override
  DateTime groupFunction(DateTime datetime) =>
      datetime.beginningOfMonth().add(const Duration(days: 15));

  @override
  YearFilter get earlier => YearFilter._(start.yearEarlier());

  @override
  YearFilter get later => YearFilter._(end);

  @override
  String get label => start.humanYear;

  @override
  final String name = 'Year';

  @override
  Widget chart(
    List<DateTimeChartValue> chartValues,
    bool absolute,
    ChartValueFormatter formatter,
  ) {
    return YearChart(
      chartValues: chartValues,
      absolute: absolute,
      formatter: formatter,
      startDateTime: start,
    );
  }
}

class AllFilter extends DateFilterState {
  const AllFilter();

  @override
  final DateTime? start = null;

  @override
  DateTime get end => DateTime.now();

  @override
  DateTime groupFunction(DateTime datetime) =>
      datetime.beginningOfMonth().add(const Duration(days: 15));

  @override
  DateFilterState get earlier => this;

  @override
  DateFilterState get later => this;

  @override
  final String label = 'All';

  @override
  final String name = 'All';

  @override
  Widget chart(
    List<DateTimeChartValue> chartValues,
    bool absolute,
    ChartValueFormatter formatter,
  ) {
    return AllChart(
      chartValues: chartValues,
      absolute: absolute,
      formatter: formatter,
    );
  }
}
