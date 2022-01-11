import 'package:intl/intl.dart';
import 'package:sport_log/models/all.dart';

String formatDatetime(DateTime dateTime) {
  return DateFormat('dd.MM.yy kk:mm').format(dateTime);
}

String formatDate(DateTime date) {
  return DateFormat('dd.MM.yy').format(date);
}

String formatTime(Duration duration, {bool short = false}) {
  if (short && duration.inSeconds < 3600) {
    return duration.toString().split('.').first.split(":").skip(1).join(":");
  } else {
    return duration.toString().split('.').first.padLeft(8, "0");
  }
}

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
  final int milliseconds = d.inMilliseconds % 1000;
  if (milliseconds != 0) {
    result += '${milliseconds}ms';
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
  final int milliSeconds = d.inMilliseconds;
  return '$milliSeconds';
}

String plural(String singular, String plural, int count) {
  return (count == 1) ? singular : plural;
}

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

String formatDistance(int meters) {
  assert(meters >= 0);
  final kmRemainder = meters % 1000;
  if (kmRemainder == 0) {
    return '${meters ~/ 1000}k';
  }
  final remainder100 = meters % 100;
  if (remainder100 == 0) {
    final km = meters.toDouble() / 1000.0;
    return '${km.toStringAsFixed(1)}k';
  }
  const double metersPerMile = 1609.344;
  final miRemainder = meters.toDouble() % metersPerMile;
  if (miRemainder < 10) {
    final miles = (meters.toDouble() / metersPerMile).round();
    return '${miles}mi';
  }
  return '${meters}m';
}

String roundedValue(double value) {
  // TODO: not quite right
  if (value % 1 == 0) {
    return value.toString();
  }
  return value.toStringAsFixed(1);
}

String roundedWeight(double weight) {
  return roundedValue(weight) + 'kg';
}

String formatCountWeight(MovementDimension dim, int count, double? weight) {
  switch (dim) {
    case MovementDimension.reps:
      return weight != null
          ? '$count x ${roundedWeight(weight)}'
          : '${count}reps';
    case MovementDimension.time:
      var result = formatDuration(Duration(milliseconds: count));
      return weight != null ? result + ' (${roundedWeight(weight)})' : result;
    case MovementDimension.energy:
      var result = '${count}cals';
      return weight != null ? result + ' (${roundedWeight(weight)})' : result;
    case MovementDimension.distance:
      var result = formatDistance(count);
      return weight != null ? result + ' (${roundedWeight(weight)})' : result;
  }
}
