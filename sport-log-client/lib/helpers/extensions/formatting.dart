import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/models/movement/movement.dart';

String plural(String singular, String plural, int count) {
  return (count == 1) ? singular : plural;
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

String roundedWeight(double weight) {
  return weight.toStringAsFixed(1) + ' kg';
}

String formatCountWeight(MovementDimension dim, int count, double? weight) {
  switch (dim) {
    case MovementDimension.reps:
      return weight != null
          ? '$count x ${roundedWeight(weight)}'
          : '$count reps';
    case MovementDimension.time:
      final result = Duration(milliseconds: count).formatTimeWithMillis;
      return weight != null ? result + ' (${roundedWeight(weight)})' : result;
    case MovementDimension.energy:
      final result = '$count cals';
      return weight != null ? result + ' (${roundedWeight(weight)})' : result;
    case MovementDimension.distance:
      final result = formatDistance(count);
      return weight != null ? result + ' (${roundedWeight(weight)})' : result;
  }
}
