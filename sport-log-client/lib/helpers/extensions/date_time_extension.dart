import 'package:intl/intl.dart';

const _shortMonthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String shortMonthNameOfInt(int month) {
  return _shortMonthNames[month - 1];
}

const _shortWeekdayNames = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

String shortWeekdayNameOfInt(int weekday) {
  return _shortWeekdayNames[weekday - 1];
}

extension FormatDuration on Duration {
  String _threeDigits(int n) {
    if (n >= 100) return "$n";
    if (n >= 10) return "0$n";
    return "00$n";
  }

  String _twoDigits(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }

  String get _twoDigitHours => _twoDigits(inHours);
  String get _twoDigitMinutes =>
      _twoDigits(inMinutes.remainder(Duration.minutesPerHour));
  String get _twoDigitSeconds =>
      _twoDigits(inSeconds.remainder(Duration.secondsPerMinute));
  String get _threeDigitMillis =>
      _threeDigits(inMilliseconds.remainder(Duration.millisecondsPerSecond));

  String get formatHms => "$_twoDigitHours:$_twoDigitMinutes:$_twoDigitSeconds";

  String get formatHm => "$_twoDigitHours:$_twoDigitMinutes";

  String get formatTimeShort =>
      inSeconds < 3600 ? "$_twoDigitMinutes:$_twoDigitSeconds" : formatHms;

  String get formatMsMill =>
      "$_twoDigitMinutes:$_twoDigitSeconds.$_threeDigitMillis";
}

extension DateTimeExtension on DateTime {
  String get shortMonthName => shortMonthNameOfInt(month);
  String get shortWeekdayName => shortWeekdayNameOfInt(weekday);

  String get _formatDate => DateFormat("dd'.' MMMM yyyy").format(this);
  String get _formatDateShort => DateFormat("dd'.' MMMM").format(this);
  String get formatDateyyyyMMdd => DateFormat('yyyy-MM-dd').format(this);

  String get _formatMonth => DateFormat('MMMM yyyy').format(this);
  String get longMonthName => DateFormat.MMMM().format(this);

  String get longWeekdayName => DateFormat.EEEE().format(this);

  String get formatHms => DateFormat.Hms().format(this);
  String get formatHm => DateFormat.Hm().format(this);

  String toHumanDateTime() => '${toHumanDay()} at $formatHm';

  String toHumanDate() => toHumanDay();

  String toHumanDay() {
    final now = DateTime.now();
    if (isOnDay(now)) {
      return 'Today';
    } else if (isOnDay(DateTime.now().dayEarlier())) {
      return 'Yesterday';
    } else if (isOnDay(DateTime.now().dayLater())) {
      return 'Tomorrow';
    } else if (isInWeek(now)) {
      return longWeekdayName;
    } else if (isInYear(now)) {
      return _formatDateShort;
    } else {
      return _formatDate;
    }
  }

  String toHumanWeek() {
    final now = DateTime.now();
    if (isInWeek(now)) {
      return 'This week';
    } else if (weekLater().isInWeek(now)) {
      return 'Last week';
    } else if (isInYear(now)) {
      final lastDay = add(const Duration(days: 6));
      return "$_formatDateShort - ${lastDay._formatDateShort}";
    } else {
      final lastDay = add(const Duration(days: 6));
      return "$_formatDate - ${lastDay._formatDate}";
    }
  }

  String toHumanMonth() {
    final now = DateTime.now();
    if (isInMonth(now)) {
      return 'This month';
    } else if (monthLater().isInMonth(now)) {
      return 'Last month';
    } else if (isInYear(now)) {
      return longMonthName;
    } else {
      return _formatMonth;
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

  DateTime beginningOfSecond() {
    return DateTime(year, month, day, hour, minute, second);
  }

  DateTime beginningOfMinute() {
    return DateTime(year, month, day, hour, minute);
  }

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
    final beginning = date.beginningOfWeek();
    return isBetween(beginning, beginning.weekLater());
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

  int get numDaysInYear => isLeapYear ? 366 : 365;
}
