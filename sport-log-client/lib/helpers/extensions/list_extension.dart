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

  bool updateAll<T>(Iterable<E> elements, {required T Function(E element) by}) {
    bool result = true;
    for (final e in elements) {
      if (!update(e, by: by)) {
        result = false;
      }
    }
    return result;
  }

  bool delete<T>(E element, {required T Function(E element) by}) {
    final int index = findIndex(element, by: by);
    if (index < 0) {
      return false;
    }
    removeAt(index);
    return true;
  }

  bool deleteAll<T>(Iterable<E> elements, {required T Function(E element) by}) {
    bool result = true;
    for (final e in elements) {
      if (!delete(e, by: by)) {
        result = false;
      }
    }
    return result;
  }

  void upsert<T>(E element, {required T Function(E element) by}) {
    if (!update(element, by: by)) {
      add(element);
    }
  }

  void upsertAll<T>(Iterable<E> elements, {required T Function(E element) by}) {
    for (final e in elements) {
      upsert(e, by: by);
    }
  }
}
