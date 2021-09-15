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
}
