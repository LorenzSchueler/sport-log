import 'package:collection/collection.dart';

extension IterableExtension<T> on Iterable<T> {
  bool everyIndexed(bool Function(int index, T element) test) =>
      mapIndexed(test).every((x) => x);
}

extension SumIterableExtension on Iterable<Duration> {
  Duration get sum {
    var sum = Duration.zero;
    for (final duration in this) {
      sum += duration;
    }
    return sum;
  }
}
