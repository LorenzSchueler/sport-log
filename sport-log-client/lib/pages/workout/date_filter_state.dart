import 'package:intl/intl.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';

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

  DateTime _start;
  TimeFrame timeFrame;

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

  void setTimeFrame(TimeFrame timeFrame) {
    this.timeFrame = timeFrame;
    _start = _beginningOfTimeFrame(DateTime.now(), timeFrame);
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

  void goBackInTime() {
    switch (timeFrame) {
      case TimeFrame.day:
        _start = _start.dayEarlier();
        break;
      case TimeFrame.week:
        _start = _start.weekEarlier();
        break;
      case TimeFrame.month:
        _start = _start.monthEarlier();
        break;
      case TimeFrame.year:
        _start = _start.yearEarlier();
        break;
      case TimeFrame.all:
        break;
    }
  }

  void goForwardInTime() {
    if (goingForwardPossible) {
      switch (timeFrame) {
        case TimeFrame.day:
          _start = _start.dayLater();
          break;
        case TimeFrame.week:
          _start = _start.weekLater();
          break;
        case TimeFrame.month:
          _start = _start.monthLater();
          break;
        case TimeFrame.year:
          _start = _start.yearLater();
          break;
        case TimeFrame.all:
          break;
      }
    }
  }

  String getLabel() {
    // TODO: deal with locale
    final dateWithoutYear = DateFormat('dd.MM.');
    final dateWithYear = DateFormat('dd.MM.yyyy');
    final monthWithoutYear = DateFormat.MMMM();
    final monthWithYear = DateFormat('MMMM yyyy');
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
        if (today.isInYear(_start)) return monthWithoutYear.format(_start);
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
