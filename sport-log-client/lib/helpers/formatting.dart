import 'package:intl/intl.dart';

String formatDuration(Duration d) {
  String result = '';
  final int days = d.inDays;
  if (days >= 1) {
    result += '${days}d';
  }
  final int hours = d.inHours % 24;
  if (hours != 0) {
    result += '${hours}h';
  }
  final int minutes = d.inMinutes % 60;
  if (minutes != 0) {
    result += '${minutes}m';
  }
  final int seconds = d.inSeconds % 60;
  if (seconds != 0) {
    result += '${seconds}s';
  }
  return result;
}

String formatDurationShort(Duration d) {
  String result = '';
  final int hours = d.inHours;
  if (hours != 0) {
    final int minutes = d.inMinutes % 60;
    result += '$hours:$minutes';
    final int seconds = d.inSeconds % 60;
    if (seconds != 0) {
      result += ':$seconds';
    }
    return result;
  }
  final int minutes = d.inMinutes;
  if (minutes != 0) {
    final int seconds = d.inSeconds % 60;
    result += '$minutes:$seconds';
    final int milliSeconds = d.inMilliseconds % 1000;
    if (milliSeconds != 0) {
      result += '.$milliSeconds';
    }
    return result;
  }
  final int seconds = d.inSeconds;
  if (seconds != 0) {
    final int milliSeconds = d.inMilliseconds % 1000;
    result += '$seconds.$milliSeconds';
    return result;
  }
  result += '0';
  return result;
}

String plural(String singular, String plural, int count) {
  return (count == 1) ? singular : plural;
}

final dateWithoutYear = DateFormat('dd.MM.');
final dateWithYear = DateFormat('dd.MM.yyyy');
final monthName = DateFormat.MMMM();
final monthWithYear = DateFormat('MMMM yyyy');
final dateTimeFull = DateFormat('dd.MM.yyyy HH:mm');

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

String shortMonthName(int month) {
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

String shortWeekdayName(int weekday) {
  return _shortWeekdayNames[weekday - 1];
}
