import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/formatting.dart';

abstract class DateFilter {
  const DateFilter();

  DateTime? get start;

  DateTime? get end;

  bool get goingForwardPossible =>
      end == null ? false : end!.isBefore(DateTime.now());

  DateFilter get earlier;

  DateFilter get later;

  /// returns String with human readable formatted date
  String get label;

  /// return static String with name of filter
  String get name;

  @override
  int get hashCode => Object.hash(runtimeType, start);

  @override
  bool operator ==(Object other) =>
      other is DateFilter && other.start == start && other.end == start;
}

class DayFilter extends DateFilter {
  const DayFilter._(this.start) : super();

  factory DayFilter.current() {
    return DayFilter._(DateTime.now().beginningOfDay());
  }

  @override
  final DateTime start;

  @override
  DateTime get end => start.dayLater();

  @override
  DayFilter get earlier => DayFilter._(start.dayEarlier());

  @override
  DayFilter get later => DayFilter._(end);

  @override
  String get label {
    final now = DateTime.now();
    if (now.isOnDay(start)) return 'Today';
    if (now.dayEarlier().isOnDay(start)) return 'Yesterday';
    if (now.isInYear(start)) return dateWithoutYear.format(start);
    return dateWithYear.format(start);
  }

  @override
  String get name => 'Today';
}

class WeekFilter extends DateFilter {
  const WeekFilter._(this.start) : super();

  factory WeekFilter.current() {
    return WeekFilter._(DateTime.now().beginningOfWeek());
  }

  @override
  final DateTime start;

  @override
  DateTime get end => start.weekLater();

  @override
  WeekFilter get earlier => WeekFilter._(start.weekEarlier());

  @override
  WeekFilter get later => WeekFilter._(end);

  @override
  String get label {
    final now = DateTime.now();
    if (now.isInWeek(start)) return 'This week';
    if (now.weekEarlier().isInWeek(start)) return 'Last week';
    final lastDay = end.dayEarlier();
    if (now.isInYear(start) && now.isInYear(lastDay)) {
      return dateWithoutYear.format(start) +
          ' - ' +
          dateWithoutYear.format(lastDay);
    }
    return dateWithYear.format(start) + ' - ' + dateWithYear.format(lastDay);
  }

  @override
  String get name => 'This Week';
}

class MonthFilter extends DateFilter {
  const MonthFilter._(this.start) : super();

  factory MonthFilter.current() {
    return MonthFilter._(DateTime.now().beginningOfMonth());
  }

  @override
  final DateTime start;

  @override
  DateTime get end => start.monthLater();

  @override
  MonthFilter get earlier => MonthFilter._(start.monthEarlier());

  @override
  MonthFilter get later => MonthFilter._(end);

  @override
  String get label {
    final now = DateTime.now();
    if (now.isInMonth(start)) return 'This month';
    if (now.monthEarlier().isInMonth(start)) return 'Last month';
    if (now.isInYear(start)) return monthName.format(start);
    return monthWithYear.format(start);
  }

  @override
  String get name => 'This Month';
}

class YearFilter extends DateFilter {
  const YearFilter._(this.start) : super();

  factory YearFilter.current() {
    return YearFilter._(DateTime.now().beginningOfYear());
  }

  @override
  final DateTime start;

  @override
  DateTime get end => start.yearLater();

  @override
  YearFilter get earlier => YearFilter._(start.yearEarlier());

  @override
  YearFilter get later => YearFilter._(end);

  @override
  String get label {
    final now = DateTime.now();
    if (now.isInYear(start)) return 'This year';
    if (now.yearEarlier().isInYear(start)) return 'Last year';
    return start.year.toString();
  }

  @override
  String get name => 'This Year';
}

class NoFilter extends DateFilter {
  const NoFilter() : super();

  @override
  String get label => 'All';

  @override
  DateFilter get earlier => this;

  @override
  DateFilter get later => this;

  @override
  String get name => 'Everything';

  @override
  DateTime? get end => null;

  @override
  DateTime? get start => null;
}
