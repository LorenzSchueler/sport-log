import 'dart:math' as math;

extension IterableExtension<T> on Iterable<T> {
  Iterable<R> mapIndexed<R>(R Function(T element, int index) convert) sync* {
    var index = 0;
    for (final element in this) {
      yield convert(element, index++);
    }
  }

  bool everyIndexed(bool Function(T element, int index) test) {
    int index = 0;
    for (final T element in this) {
      if (!test(element, index++)) return false;
    }
    return true;
  }

  Iterable<R> mapFilteredIndexed<R>(
    R? Function(T element, int index) convert,
  ) sync* {
    var index = 0;
    for (final element in this) {
      final r = convert(element, index++);
      if (r != null) {
        yield r;
      }
    }
  }

  void forEachIndexed(void Function(T element, int index) action) {
    var index = 0;
    for (final element in this) {
      action(element, index++);
    }
  }

  List<R> mapToList<R>(R Function(T) mapping) {
    return map(mapping).toList();
  }

  List<R> mapToListIndexed<R>(R Function(T element, int index) mapping) {
    return mapIndexed(mapping).toList();
  }
}

extension Iterables<E> on Iterable<E> {
  Map<K, List<V>> groupBy<K, V>(
    K Function(E) keyFunction,
    V Function(E) valueFunction,
  ) =>
      fold(
        <K, List<V>>{},
        (Map<K, List<V>> map, E element) => map
          ..putIfAbsent(keyFunction(element), () => <V>[])
              .add(valueFunction(element)),
      );
}

extension IterableInt on Iterable<int> {
  int get max => isEmpty ? 0 : reduce(math.max);
  int get min => isEmpty ? 0 : reduce(math.min);
  int get sum => isEmpty ? 0 : reduce((a, b) => a + b);
  double get avg => sum / length;
}

extension IterableDouble on Iterable<double> {
  double get max => isEmpty ? 0.0 : reduce(math.max);
  double get min => isEmpty ? 0.0 : reduce(math.min);
  double get sum => isEmpty ? 0.0 : reduce((a, b) => a + b);
  double get avg => sum / length;
}

extension IterableIntOptional on Iterable<int?> {
  Iterable<int> get filterNotNull => where((e) => e != null).cast();
  int get max => filterNotNull.max;
  int get min => filterNotNull.min;
  int get sum => filterNotNull.sum;
  double get avg => filterNotNull.avg;
}

extension IterableDoubleOptional on Iterable<double?> {
  Iterable<double> get filterNotNull => where((e) => e != null).cast();
  double get max => filterNotNull.max;
  double get min => filterNotNull.min;
  double get sum => filterNotNull.sum;
  double get avg => filterNotNull.avg;
}

extension IterableDateTime on Iterable<DateTime> {
  DateTime? get max =>
      isEmpty ? null : reduce((d1, d2) => d1.compareTo(d2) > 0 ? d1 : d2);
  DateTime? get min =>
      isEmpty ? null : reduce((d1, d2) => d1.compareTo(d2) < 0 ? d1 : d2);
}
