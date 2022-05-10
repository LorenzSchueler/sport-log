import 'package:fuzzywuzzy/applicable.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';

class _SortAlgorithm implements Applicable {
  @override
  int apply(String s1, String s2) => tokenSortRatio(s1, s2);
}

extension SortExtension<T> on List<T> {
  List<T> fuzzySortByKey({
    required String? key,
    required String Function(T) toString,
  }) {
    return key == null || key.isEmpty
        ? this
        : extractAllSorted(
            query: key,
            choices: this,
            getter: toString,
            ratio: _SortAlgorithm(),
          ).map((e) => e.choice).toList();
  }
}
