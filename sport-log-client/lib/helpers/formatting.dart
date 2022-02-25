import 'package:intl/intl.dart';
import 'package:sport_log/models/all.dart';

extension FormatDateTime on DateTime {
  String get formatDatetime => DateFormat('dd.MM.yy kk:mm').format(this);

  String get formatDate => DateFormat('dd.MM.yy').format(this);

  String get yyyyMMdd => DateFormat('yyyy-MM-dd').format(this);
}

extension FormatDuration on Duration {
  String get formatTime => toString().split('.').first.padLeft(8, "0");

  String get formatTimeShort => inSeconds < 3600
      ? toString().split('.').first.split(":").skip(1).join(":")
      : toString().split('.').first.padLeft(8, "0");

  String get formatTimeWithMillis => toString().split(":").skip(1).join(":");
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
      final result = Duration(milliseconds: count).formatTimeWithMillis;
      return weight != null ? result + ' (${roundedWeight(weight)})' : result;
    case MovementDimension.energy:
      final result = '${count}cals';
      return weight != null ? result + ' (${roundedWeight(weight)})' : result;
    case MovementDimension.distance:
      final result = formatDistance(count);
      return weight != null ? result + ' (${roundedWeight(weight)})' : result;
  }
}
