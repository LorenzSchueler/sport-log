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
