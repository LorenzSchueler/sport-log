import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension TimeOfDayExtension on TimeOfDay {
  DateTime toDateTime() {
    final now = DateTime.now();

    return DateTime(now.year, now.month, now.day, hour, minute);
  }
}

extension DateTimeExtension on DateTime {
  DateTime beginningOfDay() {
    return DateTime(year, month, day);
  }

  DateTime beginningOfWeek() {
    final difference = weekday - DateTime.monday;
    return DateTime(year, month, day).subtract(Duration(days: difference));
  }

  DateTime beginningOfMonth() {
    return DateTime(year, month);
  }

  DateTime beginningOfYear() {
    return DateTime(year);
  }

  DateTime endOfDay() {
    return DateTime(year, month, day + 1);
  }

  DateTime endOfWeek() {
    return beginningOfWeek().weekLater();
  }

  DateTime endOfMonth() {
    return DateTime(year, month + 1, 1);
  }

  DateTime endOfYear() {
    return DateTime(year + 1);
  }

  DateTime dayLater() {
    return DateTime(year, month, day + 1);
  }

  DateTime weekLater() {
    return DateTime(year, month, day + 7);
  }

  DateTime monthLater() {
    return DateTime(year, month + 1, day);
  }

  DateTime yearLater() {
    return DateTime(year + 1, month, day);
  }

  DateTime dayEarlier() {
    return DateTime(year, month, day - 1);
  }

  DateTime weekEarlier() {
    return DateTime(year, month, day - 7);
  }

  DateTime monthEarlier() {
    return DateTime(year, month - 1, day);
  }

  DateTime yearEarlier() {
    return DateTime(year - 1, month, day);
  }

  // start inclusive, end exclusive
  bool isBetween(DateTime start, DateTime end) {
    return isAtSameMomentAs(start) || (isAfter(start) && isBefore(end));
  }

  bool isOnDay(DateTime date) {
    return day == date.day && month == date.month && year == date.year;
  }

  bool isInWeek(DateTime date) {
    final _date = date.beginningOfWeek();
    return isBetween(_date, _date.weekLater());
  }

  bool isInMonth(DateTime date) {
    return month == date.month && year == date.year;
  }

  bool isInYear(DateTime date) {
    return year == date.year;
  }

  bool get isLeapYear {
    return (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
  }

  int get numDaysInMonth {
    const numDaysNormYear = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    const numDaysLeapYear = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return isLeapYear ? numDaysLeapYear[month - 1] : numDaysNormYear[month - 1];
  }

  static final _dateWithoutYear = DateFormat('dd.MM.');
  static final _dateWithYear = DateFormat('dd.MM.yyyy');
  static final _dateTimeFull = DateFormat('dd.MM.yyyy HH:mm');
  static final _timeFull = DateFormat('HH:mm');
  static final _monthName = DateFormat.MMMM();
  static final _monthNameWithYear = DateFormat('MMMM yyyy');
  static final _timeHourMinute = DateFormat.Hm();
  static final _longWeekday = DateFormat.EEEE();

  String toStringDateWithoutYear() {
    return _dateWithoutYear.format(this);
  }

  String toStringDateWithYear() {
    return _dateWithYear.format(this);
  }

  String toStringDateTime() {
    return _dateTimeFull.format(this);
  }

  String toStringTime() {
    return _timeFull.format(this);
  }

  String toStringMonthWithoutYear() {
    return _monthName.format(this);
  }

  String toStringMonthWithYear() {
    return _monthNameWithYear.format(this);
  }

  String toStringHourMinute() {
    return _timeHourMinute.format(this);
  }

  String toStringWeekday() {
    return _longWeekday.format(this);
  }

  String toHumanDay() {
    final now = DateTime.now();
    if (isOnDay(now)) {
      return 'Today';
    } else if (isOnDay(DateTime.now().dayEarlier())) {
      return 'Yesterday';
    } else if (isInWeek(now)) {
      return toStringWeekday();
    } else {
      return toStringDateWithYear();
    }
  }

  String toHumanWithTime() {
    return '${toHumanDay()} at ${toStringHourMinute()}';
  }

  String toHumanWeek() {
    final now = DateTime.now();
    if (isInWeek(now)) {
      return 'This week';
    }
    if (weekLater().isInWeek(now)) {
      return 'Last week';
    }
    final lastDay = add(const Duration(days: 6));
    if (isInYear(now) && isInYear(lastDay)) {
      return toStringDateWithoutYear() + ' - ' + toStringDateWithoutYear();
    }
    return toStringDateWithYear() + ' - ' + lastDay.toStringDateWithYear();
  }

  String toHumanMonth() {
    final now = DateTime.now();
    if (isInMonth(now)) {
      return 'This month';
    } else if (monthLater().isInMonth(now)) {
      return 'Last month';
    } else if (isInYear(now)) {
      return toStringMonthWithoutYear();
    } else {
      return toStringMonthWithYear();
    }
  }

  String toHumanYear() {
    final now = DateTime.now();
    if (isInYear(now)) {
      return 'This year';
    } else if (yearLater().isInYear(now)) {
      return 'Last year';
    } else {
      return year.toString();
    }
  }

  DateTime withTime(TimeOfDay time) {
    return DateTime(year, month, day, time.hour, time.minute);
  }
}
