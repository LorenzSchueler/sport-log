extension ListExtension<E> on List<E> {
  void sortBy<T extends Comparable<T>>(T Function(E element) getField) {
    sort((E e1, E e2) => getField(e1).compareTo(getField(e2)));
  }

  int findIndex<T>(E element, {required T Function(E element) by}) {
    final T t = by(element);
    return indexWhere((e) => by(e) == t);
  }

  bool update<T>(E element, {required T Function(E element) by}) {
    final int index = findIndex(element, by: by);
    if (index < 0) {
      return false;
    }
    this[index] = element;
    return true;
  }

  bool delete<T>(E element, {required T Function(E element) by}) {
    final int index = findIndex(element, by: by);
    if (index < 0) {
      return false;
    }
    removeAt(index);
    return true;
  }
}
