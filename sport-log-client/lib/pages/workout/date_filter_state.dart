import 'package:intl/intl.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';

enum TimeFrame { day, week, month, year, all }

extension ToDisplayName on TimeFrame {
  String toDisplayName() {
    switch (this) {
      case TimeFrame.day:
        return 'Day';
      case TimeFrame.week:
        return 'Week';
      case TimeFrame.month:
        return 'Month';
      case TimeFrame.year:
        return 'Year';
      case TimeFrame.all:
        return 'All';
    }
  }
}

// most elegant piece of code I've ever written :)
class DateFilterState {
  DateFilterState({required DateTime start, required this.timeFrame})
      : start = _beginningOfTimeFrame(start, timeFrame);

  DateTime start;
  TimeFrame timeFrame;

  DateTime get end {
    switch (timeFrame) {
      case TimeFrame.day:
        return start.dayLater();
      case TimeFrame.week:
        return start.weekLater();
      case TimeFrame.month:
        return start.monthLater();
      case TimeFrame.year:
        return start.yearLater();
      case TimeFrame.all:
        return start;
    }
  }

  static DateTime _beginningOfTimeFrame(DateTime start, TimeFrame duration) {
    switch (duration) {
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
    start = _beginningOfTimeFrame(start, timeFrame);
  }

  bool get goingForwardPossible {
    switch (timeFrame) {
      case TimeFrame.day:
        return start.endOfDay().isBefore(DateTime.now());
      case TimeFrame.week:
        return start.endOfWeek().isBefore(DateTime.now());
      case TimeFrame.month:
        return start.endOfMonth().isBefore(DateTime.now());
      case TimeFrame.year:
        return start.endOfYear().isBefore(DateTime.now());
      case TimeFrame.all:
        return false;
    }
  }

  void goBackInTime() {
    switch (timeFrame) {
      case TimeFrame.day:
        start = start.dayEarlier();
        break;
      case TimeFrame.week:
        start = start.weekEarlier();
        break;
      case TimeFrame.month:
        start = start.monthEarlier();
        break;
      case TimeFrame.year:
        start = start.yearEarlier();
        break;
      case TimeFrame.all:
        break;
    }
  }

  void goForwardInTime() {
    if (goingForwardPossible) {
      switch (timeFrame) {
        case TimeFrame.day:
          start = start.dayLater();
          break;
        case TimeFrame.week:
          start = start.weekLater();
          break;
        case TimeFrame.month:
          start = start.monthLater();
          break;
        case TimeFrame.year:
          start = start.yearLater();
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
        if (start.isAtSameMomentAs(today)) return 'Today';
        if (start.isAtSameMomentAs(today.dayEarlier())) return 'Yesterday';
        if (today.isInYear(start)) return dateWithoutYear.format(start);
        return dateWithYear.format(start);
      case TimeFrame.week:
        if (today.isInWeek(start)) return 'This week';
        final weekLater = start.weekLater();
        if (today.isInWeek(weekLater)) return 'Last week';
        final endDate = weekLater.dayEarlier();
        if (start.isInYear(today) && weekLater.isInYear(today)) {
          return dateWithoutYear.format(start) +
              ' - ' +
              dateWithoutYear.format(endDate);
        }
        return dateWithYear.format(start) +
            ' - ' +
            dateWithYear.format(endDate);
      case TimeFrame.month:
        if (today.isInMonth(start)) return 'This month';
        if (today.isInMonth(start.monthLater())) return 'Last month';
        if (today.isInYear(start)) return monthWithoutYear.format(start);
        return monthWithYear.format(start);
      case TimeFrame.year:
        if (today.isInYear(start)) return 'This year';
        if (today.isInYear(start.yearLater())) return 'Last year';
        return start.year.toString();
      case TimeFrame.all:
        return 'All';
    }
  }
}
