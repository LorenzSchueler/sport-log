extension NumExtension on num {
  num? addNullable(num? other) => other == null ? null : this + other;
  num? subNullable(num? other) => other == null ? null : this - other;
  num? mulNullable(num? other) => other == null ? null : this * other;
}

bool isRecord(num? current, num? record, {bool minRecord = false}) {
  return current == null || current == 0
      ? false
      : record == null
          ? true
          : minRecord
              ? current <= record
              : current >= record;
}
