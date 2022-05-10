import 'package:collection/collection.dart';

extension IterableExtension<T> on Iterable<T> {
  bool everyIndexed(bool Function(int index, T element) test) =>
      mapIndexed(test).every((x) => x);
}

extension NullableIterableExtension<T> on Iterable<T?> {
  Iterable<T> filterNotNull() => where((e) => e != null).cast();
}

extension IterableDateTime on Iterable<DateTime> {
  DateTime? get max =>
      isEmpty ? null : reduce((d1, d2) => d1.compareTo(d2) > 0 ? d1 : d2);
  DateTime? get min =>
      isEmpty ? null : reduce((d1, d2) => d1.compareTo(d2) < 0 ? d1 : d2);
}
