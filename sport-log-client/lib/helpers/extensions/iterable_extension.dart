

extension IterableExtension<T> on Iterable<T> {
  Iterable<R> mapIndexed<R>(R Function(int index, T element) convert) sync* {
    var index = 0;
    for (var element in this) {
      yield convert(index++, element);
    }
  }

  bool everyIndexed(bool Function(T element, int index) test) {
    int index = 0;
    for (T element in this) {
      if (!test(element, index++)) return false;
    }
    return true;
  }
}