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
      R? Function(T element, int index) convert) sync* {
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

  List<R> mapToL<R>(R Function(T) mapping) {
    return map(mapping).toList();
  }

  List<R> mapToLIndexed<R>(R Function(T element, int index) mapping) {
    return mapIndexed(mapping).toList();
  }
}
