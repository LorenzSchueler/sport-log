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

extension SortExtension<T> on Iterable<T> {
  List<T> fuzzySort({
    required String? query,
    required String Function(T) toString,
  }) {
    if (query == null || query.isEmpty) return toList();

    final sortedItems =
        map(
            (candidate) =>
                SortItem<T>(distance(query, toString(candidate)), candidate),
          ).toList()
          ..sort((x, y) => x.score.compareTo(y.score));

    return sortedItems.map((e) => e.item).toList();
  }
}

int distance(
  String query,
  String candidate, {
  int insert = 1,
  int edit = 3,
  int delete = 6,
}) {
  final queryLc = query.toLowerCase().replaceAll("-", " ");
  final candidateLc = candidate.toLowerCase().replaceAll("-", " ");

  if (queryLc == candidateLc) {
    return 0;
  }

  if (queryLc.isEmpty) {
    return candidateLc.length * insert;
  }

  if (candidateLc.isEmpty) {
    return queryLc.length * delete;
  }

  var v0 = List<int>.generate(
    candidateLc.length + 1,
    (i) => i * insert,
    growable: false,
  );
  var v1 = List<int>.filled(candidateLc.length + 1, 0);
  List<int> vtemp;

  for (var i = 1; i <= queryLc.length; i++) {
    v1[0] = i * delete;

    for (var j = 1; j <= candidateLc.length; j++) {
      var cost = edit;
      if (queryLc.codeUnitAt(i - 1) == candidateLc.codeUnitAt(j - 1)) {
        cost = 0;
      }
      v1[j] = [
        v1[j - 1] + insert,
        v0[j] + delete,
        v0[j - 1] + cost,
      ].reduce(min);
    }

    vtemp = v0;
    v0 = v1;
    v1 = vtemp;
  }

  final directMatch = candidateLc.contains(queryLc) ? 0 : 1000;

  return v0[candidateLc.length] + directMatch;
}
