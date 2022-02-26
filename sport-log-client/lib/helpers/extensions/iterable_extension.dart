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
    for (T element in this) {
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

extension IterableNum<T extends num> on Iterable<T> {
  T get max => isEmpty ? 0 as T : reduce(math.max);
  T get min => isEmpty ? 0 as T : reduce(math.min);
  T get sum => isEmpty ? 0 as T : reduce((a, b) => a + b as T);
}

extension IterableNumOptional<T extends num> on Iterable<T?> {
  T? get max => isEmpty
      ? null
      : reduce((a, b) {
          if (a != null && b != null) {
            return math.max(a, b);
          } else {
            return a ?? b;
          }
        });
  T? get min => isEmpty
      ? null
      : reduce((a, b) {
          if (a != null && b != null) {
            return math.min(a, b);
          } else {
            return a ?? b;
          }
        });
  T? get sum => isEmpty
      ? null
      : reduce((a, b) {
          if (a != null && b != null) {
            return a + b as T;
          } else {
            return a ?? b;
          }
        });
}
