import 'dart:math';

class SortItem<T> {
  const SortItem(this.score, this.item);

  final int score;
  final T item;

  @override
  String toString() {
    return "$item: $score";
  }
}

extension SortExtension<T> on List<T> {
  List<T> fuzzySort({
    required String? query,
    required String Function(T) toString,
  }) {
    if (query == null || query.isEmpty) return this;

    final sortedItems = map(
      (candidate) =>
          SortItem<T>(distance(query, toString(candidate)), candidate),
    ).toList()
      ..sort((x, y) => x.score.compareTo(y.score));

    return sortedItems.map((e) => e.item).toList();
  }
}

int distance(
  String query,
  String canditate, {
  int insert = 1,
  int edit = 3,
  int delete = 6,
}) {
  query = query.toLowerCase().replaceAll("-", " ");
  canditate = canditate.toLowerCase().replaceAll("-", " ");

  if (query == canditate) {
    return 0;
  }

  if (query.isEmpty) {
    return canditate.length * insert;
  }

  if (canditate.isEmpty) {
    return query.length * delete;
  }

  List<int> v0 = List<int>.generate(
    canditate.length + 1,
    (i) => i * insert,
    growable: false,
  );
  List<int> v1 = List<int>.filled(canditate.length + 1, 0, growable: false);
  List<int> vtemp;

  for (var i = 1; i <= query.length; i++) {
    v1[0] = i * delete;

    for (var j = 1; j <= canditate.length; j++) {
      int cost = edit;
      if (query.codeUnitAt(i - 1) == canditate.codeUnitAt(j - 1)) {
        cost = 0;
      }
      v1[j] =
          [v1[j - 1] + insert, v0[j] + delete, v0[j - 1] + cost].reduce(min);
    }

    vtemp = v0;
    v0 = v1;
    v1 = vtemp;
  }

  final directMatch = canditate.contains(query) ? 0 : 1000;

  return v0[canditate.length] + directMatch;
}
