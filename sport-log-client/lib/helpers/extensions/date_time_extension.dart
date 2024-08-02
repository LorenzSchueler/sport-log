import 'package:intl/intl.dart';

extension DurationExtension on Duration {
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
  String get _twoDigitMinutes99 => _twoDigits(inMinutes);
  String get _twoDigitSeconds =>
      _twoDigits(inSeconds.remainder(Duration.secondsPerMinute));
  String get _threeDigitMillis =>
      _threeDigits(inMilliseconds.remainder(Duration.millisecondsPerSecond));

  String get formatHms => "$_twoDigitHours:$_twoDigitMinutes:$_twoDigitSeconds";

  String get formatHm => "$_twoDigitHours:$_twoDigitMinutes";

  String get formatTimeShort =>
      inSeconds < 3600 ? "$_twoDigitMinutes:$_twoDigitSeconds" : formatHms;

  String get formatM99S => "$_twoDigitMinutes99:$_twoDigitSeconds";

  String get formatMsMill =>
      "$_twoDigitMinutes:$_twoDigitSeconds.$_threeDigitMillis";

  bool get isZero => inMilliseconds == 0;
  double get inSecondFractions => inMilliseconds / 1000;
  double get inMinuteFractions => inMilliseconds / 60 / 1000;
  double get inHourFractions => inMilliseconds / 60 / 60 / 1000;
}

extension DateTimeExtension on DateTime {
  /// example: 01. February 2000
  String get dayMonthNameYear => DateFormat("dd'.' MMMM yyyy").format(this);

  /// example: 01. February
  String get dayMonthName => DateFormat("dd'.' MMMM").format(this);

  /// example: 2000-02-01
  String get yearMonthDay => DateFormat("yyyy-MM-dd").format(this);

  /// example: February 2000
  String get monthNameYear => DateFormat("MMMM yyyy").format(this);

  /// example: February
  String get longMonthName => DateFormat.MMMM().format(this);

  /// example: Feb
  String get shortMonthName => DateFormat.MMM().format(this);

  /// example: Monday
  String get longWeekdayName => DateFormat.EEEE().format(this);

  /// example: Mon
  String get shortWeekdayName => DateFormat("EEE").format(this);

  /// example: 01:02:03
  String get hourMinuteSecond => DateFormat.Hms().format(this);

  /// example: 01:02
  String get hourMinute => DateFormat.Hm().format(this);

  /// examples:
  /// Today at 01:02,
  /// Yesterday at 01:02,
  /// Tomorrow at 01:02,
  /// Monday at 01:02,
  /// 01. February at 01:02,
  /// 01. February 2000 at 01:02,
  String get humanDateTime => "$humanDate at $hourMinute";

  /// examples:
  /// Today at 01:02,
  /// Yesterday,
  /// Tomorrow,
  /// Monday,
  /// 01. February,
  /// 01. February 2022,
  String get humanTodayTimeOrDate =>
      isOnDay(DateTime.now()) ? humanDateTime : humanDate;

  /// examples:
  /// Today,
  /// Yesterday,
  /// Tomorrow,
  /// Monday,
  /// 01. February,
  /// 01. February 2000,
  String get humanDate {
    final now = DateTime.now();
    if (isOnDay(now)) {
      return "Today";
    } else if (isOnDay(DateTime.now().dayEarlier())) {
      return "Yesterday";
    } else if (isOnDay(DateTime.now().dayLater())) {
      return "Tomorrow";
    } else if (isInWeek(now)) {
      return longWeekdayName;
    } else if (isInYear(now)) {
      return dayMonthName;
    } else {
      return dayMonthNameYear;
    }
  }

  /// examples:
  /// This Week,
  /// Last Week,
  /// 01. February - 08. February,
  /// 01. February 2000 - 08. February 2000
  String get humanWeek {
    final now = DateTime.now();
    if (isInWeek(now)) {
      return "This Week";
    } else if (weekLater().isInWeek(now)) {
      return "Last Week";
    } else if (isInYear(now)) {
      final lastDay = add(const Duration(days: 6));
      return "$dayMonthName - ${lastDay.dayMonthName}";
    } else {
      final lastDay = add(const Duration(days: 6));
      return "$dayMonthNameYear - ${lastDay.dayMonthNameYear}";
    }
  }

  /// examples:
  /// This Month,
  /// Last Month,
  /// February,
  /// February 2000
  String get humanMonth {
    final now = DateTime.now();
    if (isInMonth(now)) {
      return "This Month";
    } else if (monthLater().isInMonth(now)) {
      return "Last Month";
    } else if (isInYear(now)) {
      return longMonthName;
    } else {
      return monthNameYear;
    }
  }

  /// examples:
  /// This Year,
  /// Last Year,
  /// 2000
  String get humanYear {
    final now = DateTime.now();
    if (isInYear(now)) {
      return "This Year";
    } else if (yearLater().isInYear(now)) {
      return "Last Year";
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
    return DateTime(year, month + 1);
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

  bool get _isLeapYear {
    return (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
  }

  int get numDaysInMonth {
    const numDaysNormYear = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    const numDaysLeapYear = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return _isLeapYear
        ? numDaysLeapYear[month - 1]
        : numDaysNormYear[month - 1];
  }

  int get numDaysInYear => _isLeapYear ? 366 : 365;
}
