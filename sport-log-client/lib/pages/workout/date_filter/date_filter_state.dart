import 'package:sport_log/helpers/extensions/date_time_extension.dart';

abstract class DateFilterState {
  const DateFilterState();

  DateTime? get start;

  DateTime? get end;

  bool get goingForwardPossible =>
      end == null ? false : end!.isBefore(DateTime.now());

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

  static DateFilterState get init => MonthFilter(DateTime.now());
}

class DayFilter extends DateFilterState {
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
  String get label => start.toHumanDay();

  @override
  String get name => 'Day';
}

class WeekFilter extends DateFilterState {
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
  String get label => start.toHumanWeek();

  @override
  String get name => 'Week';
}

class MonthFilter extends DateFilterState {
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
  String get label => start.toHumanMonth();

  @override
  String get name => 'Month';
}

class YearFilter extends DateFilterState {
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
  String get label => start.toHumanYear();

  @override
  String get name => 'Year';
}

class NoFilter extends DateFilterState {
  const NoFilter() : super();

  @override
  String get label => 'All';

  @override
  DateFilterState get earlier => this;

  @override
  DateFilterState get later => this;

  @override
  String get name => 'All';

  @override
  DateTime? get end => null;

  @override
  DateTime? get start => null;
}
