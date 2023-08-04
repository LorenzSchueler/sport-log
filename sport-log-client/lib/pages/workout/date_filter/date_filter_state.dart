import 'package:sport_log/helpers/extensions/date_time_extension.dart';

abstract class DateFilterState {
  const DateFilterState();

  DateTime? get start;

  DateTime get end;

  bool get goingForwardPossible => end.isBefore(DateTime.now());

  DateFilterState get earlier;

  DateFilterState get later;

  /// returns String with human readable formatted date
  String get label;

  /// return static String with name of filter
  String get name;

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
      const AllFilter()
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
  DayFilter get earlier => DayFilter._(start.dayEarlier());

  @override
  DayFilter get later => DayFilter._(end);

  @override
  String get label => start.humanDate;

  @override
  final String name = 'Day';
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
  WeekFilter get earlier => WeekFilter._(start.weekEarlier());

  @override
  WeekFilter get later => WeekFilter._(end);

  @override
  String get label => start.humanWeek;

  @override
  final String name = 'Week';
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
  MonthFilter get earlier => MonthFilter._(start.monthEarlier());

  @override
  MonthFilter get later => MonthFilter._(end);

  @override
  String get label => start.humanMonth;

  @override
  final String name = 'Month';
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
  YearFilter get earlier => YearFilter._(start.yearEarlier());

  @override
  YearFilter get later => YearFilter._(end);

  @override
  String get label => start.humanYear;

  @override
  final String name = 'Year';
}

class AllFilter extends DateFilterState {
  const AllFilter();

  @override
  final DateTime? start = null;

  @override
  DateTime get end => DateTime.now();

  @override
  DateFilterState get earlier => this;

  @override
  DateFilterState get later => this;

  @override
  final String label = 'All';

  @override
  final String name = 'All';
}
