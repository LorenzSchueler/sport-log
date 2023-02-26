import 'package:fixnum/fixnum.dart';
import 'package:sport_log/models/cardio/position.dart';
import 'package:sport_log/models/entity_interfaces.dart';

extension CloneDateTime on DateTime {
  DateTime clone() =>
      DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
}

extension CloneDuration on Duration {
  Duration clone() => Duration(milliseconds: inMilliseconds);
}

extension CloneInt64 on Int64 {
  Int64 clone() => Int64.parseInt(toString());
}

extension CloneListDuration on List<Duration> {
  List<Duration> clone() => map((d) => d.clone()).toList();
}

extension CloneListPosition on List<Position> {
  List<Position> clone() => map((d) => d.clone()).toList();
}

extension CloneListEntity<E extends Entity> on List<E> {
  List<E> clone() => map((d) => d.clone()).toList().cast();
}
