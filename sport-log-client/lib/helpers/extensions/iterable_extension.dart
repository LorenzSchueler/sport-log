import 'package:collection/collection.dart';

extension IterableExtension<T> on Iterable<T> {
  bool everyIndexed(bool Function(int index, T element) test) =>
      mapIndexed(test).every((x) => x);
}

extension NullableIterableExtension<T> on Iterable<T?> {
  Iterable<T> filterNotNull() => where((e) => e != null).cast();
}
