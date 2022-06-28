import 'package:collection/collection.dart';

extension IterableExtension<T> on Iterable<T> {
  bool everyIndexed(bool Function(int index, T element) test) =>
      mapIndexed(test).every((x) => x);
}
