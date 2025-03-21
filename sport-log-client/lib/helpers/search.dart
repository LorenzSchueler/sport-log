/// Returns the index of the largest element in the list that is less or equal than value or null of no such element exists.
///
/// Assumes the list is sorted ascending and there are no duplicate elements.
int? binarySearchLargestLE<T, V extends Comparable<V>>(
  List<T> list,
  V Function(T) getter,
  V value,
) {
  _Range helper(_Range range) {
    return range.hasOneElement
        ? range
        : getter(list[range.middle + 1]).compareTo(value) <= 0
        ? helper(range.divideMiddleUpperHalf())
        : helper(range.divideMiddleLowerHalf());
  }

  if (list.isEmpty || getter(list.first).compareTo(value) > 0) {
    return null;
  }
  return helper(_Range(0, list.length - 1)).start;
}

/// Returns the index of the smallest element in the list that is greater or equal than value or null of no such element exists.
///
/// Assumes the list is sorted ascending and there are no duplicate elements.
int? binarySearchSmallestGE<T, V extends Comparable<V>>(
  List<T> list,
  V Function(T) getter,
  V value,
) {
  _Range helper(_Range range) {
    return range.hasOneElement
        ? range
        : getter(list[range.middle]).compareTo(value) >= 0
        ? helper(range.divideMiddleLowerHalf())
        : helper(range.divideMiddleUpperHalf());
  }

  if (list.isEmpty || getter(list.last).compareTo(value) < 0) {
    return null;
  }
  return helper(_Range(0, list.length - 1)).start;
}

/// Returns the index of element in the list with the smallest difference to the given value.
///
/// Assumes the list is sorted ascending and there are no duplicate elements.
int? binarySearchClosest<T>(List<T> list, num Function(T) getter, num value) {
  final index = binarySearchLargestLE(list, getter, value);

  if (index == null && list.isNotEmpty) {
    return 0; // first element is already greater than value
  } else if (index != null) {
    return list.length == index + 1
        ? index
        : value - getter(list[index]) <= getter(list[index + 1]) - value
        ? index
        : index + 1;
  }
  return null;
}

/// An inclusive range.
class _Range {
  const _Range(this.start, this.end) : assert(start <= end);

  final int start;
  final int end;

  int get middle => ((start + end) / 2).floor();
  bool get hasOneElement => start == end;

  /// Range from start to middle.
  _Range divideMiddleLowerHalf() => _Range(start, middle);

  /// Range from middle+1 to end.
  /// Middle must be smaller than end, which is the case if isOneElement is false.
  _Range divideMiddleUpperHalf() => _Range(middle + 1, end);

  @override
  String toString() {
    return "$start..$end";
  }
}
