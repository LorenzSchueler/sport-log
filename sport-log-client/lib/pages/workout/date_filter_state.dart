import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/formatting.dart';

enum TimeFrame { day, week, month, year, all }

extension ToDisplayName on TimeFrame {
  String toDisplayName() {
    switch (this) {
      case TimeFrame.day:
        return 'Today';
      case TimeFrame.week:
        return 'This week';
      case TimeFrame.month:
        return 'This month';
      case TimeFrame.year:
        return 'This year';
      case TimeFrame.all:
        return 'All';
    }
  }
}

// most elegant piece of code I've ever written :)
class DateFilterState {
  DateFilterState({required DateTime start, required this.timeFrame})
      : _start = _beginningOfTimeFrame(start, timeFrame);

  DateFilterState._(this._start, this.timeFrame);

  final DateTime _start;
  final TimeFrame timeFrame;

  DateTime? get end {
    switch (timeFrame) {
      case TimeFrame.day:
        return _start.dayLater();
      case TimeFrame.week:
        return _start.weekLater();
      case TimeFrame.month:
        return _start.monthLater();
      case TimeFrame.year:
        return _start.yearLater();
      case TimeFrame.all:
        return null;
    }
  }

  DateTime? get start {
    return timeFrame == TimeFrame.all ? null : _start;
  }

  DateFilterState copy() {
    return DateFilterState._(_start.copy(), timeFrame);
  }

  @override
  bool operator ==(Object other) =>
      other is DateFilterState &&
      other._start == start &&
      other.timeFrame == timeFrame;

  @override
  int get hashCode => Object.hash(_start, timeFrame);

  static DateTime _beginningOfTimeFrame(DateTime start, TimeFrame timeFrame) {
    switch (timeFrame) {
      case TimeFrame.day:
        return start.beginningOfDay();
      case TimeFrame.week:
        return start.beginningOfWeek();
      case TimeFrame.month:
        return start.beginningOfMonth();
      case TimeFrame.year:
        return start.beginningOfYear();
      case TimeFrame.all:
        return start;
    }
  }

  DateFilterState withTimeFrame(TimeFrame timeFrame) {
    return DateFilterState._(
        _beginningOfTimeFrame(DateTime.now(), timeFrame), timeFrame);
  }

  bool get goingForwardPossible {
    switch (timeFrame) {
      case TimeFrame.day:
        return _start.endOfDay().isBefore(DateTime.now());
      case TimeFrame.week:
        return _start.endOfWeek().isBefore(DateTime.now());
      case TimeFrame.month:
        return _start.endOfMonth().isBefore(DateTime.now());
      case TimeFrame.year:
        return _start.endOfYear().isBefore(DateTime.now());
      case TimeFrame.all:
        return false;
    }
  }

  DateFilterState goBackInTime() {
    switch (timeFrame) {
      case TimeFrame.day:
        return DateFilterState._(_start.dayEarlier(), timeFrame);
      case TimeFrame.week:
        return DateFilterState._(_start.weekEarlier(), timeFrame);
      case TimeFrame.month:
        return DateFilterState._(_start.monthEarlier(), timeFrame);
      case TimeFrame.year:
        return DateFilterState._(_start.yearEarlier(), timeFrame);
      case TimeFrame.all:
        return copy();
    }
  }

  DateFilterState goForwardInTime() {
    if (!goingForwardPossible) {
      return copy();
    }
    switch (timeFrame) {
      case TimeFrame.day:
        return DateFilterState._(_start.dayLater(), timeFrame);
      case TimeFrame.week:
        return DateFilterState._(_start.weekLater(), timeFrame);
      case TimeFrame.month:
        return DateFilterState._(_start.monthLater(), timeFrame);
      case TimeFrame.year:
        return DateFilterState._(_start.yearLater(), timeFrame);
      case TimeFrame.all:
        return copy();
    }
  }

  String getLabel() {
    // TODO: deal with locale
    final today = DateTime.now().beginningOfDay();
    switch (timeFrame) {
      case TimeFrame.day:
        if (_start.isAtSameMomentAs(today)) return 'Today';
        if (_start.isAtSameMomentAs(today.dayEarlier())) return 'Yesterday';
        if (today.isInYear(_start)) return dateWithoutYear.format(_start);
        return dateWithYear.format(_start);
      case TimeFrame.week:
        if (today.isInWeek(_start)) return 'This week';
        final weekLater = _start.weekLater();
        if (today.isInWeek(weekLater)) return 'Last week';
        final endDate = weekLater.dayEarlier();
        if (_start.isInYear(today) && weekLater.isInYear(today)) {
          return dateWithoutYear.format(_start) +
              ' - ' +
              dateWithoutYear.format(endDate);
        }
        return dateWithYear.format(_start) +
            ' - ' +
            dateWithYear.format(endDate);
      case TimeFrame.month:
        if (today.isInMonth(_start)) return 'This month';
        if (today.isInMonth(_start.monthLater())) return 'Last month';
        if (today.isInYear(_start)) return monthName.format(_start);
        return monthWithYear.format(_start);
      case TimeFrame.year:
        if (today.isInYear(_start)) return 'This year';
        if (today.isInYear(_start.yearLater())) return 'Last year';
        return _start.year.toString();
      case TimeFrame.all:
        return 'All';
    }
  }
}
