import 'package:flutter_test/flutter_test.dart';
import 'package:sport_log/helpers/serialization/db_serialization.dart';
import 'package:sport_log/models/all.dart';

void main() {
  test('test position list', () {
    List<Position> positions1 = [
      Position(
          longitude: 32.234,
          latitude: 52.3423,
          elevation: 8849,
          distance: 1034,
          time: 300),
      Position(
          longitude: 32.632,
          latitude: 52.3564,
          elevation: -56,
          distance: 2303,
          time: 702),
      Position(
          longitude: 32.653,
          latitude: 52.4330,
          elevation: 0,
          distance: 2934,
          time: 1100),
    ];

    final blob = const DbPositionListConverter().mapToSql(positions1);

    final positions2 = const DbPositionListConverter().mapToDart(blob);

    expect(positions2 != null, true);
    expect(positions1.length, positions2!.length);

    for (int i = 0; i < positions1.length; ++i) {
      expect(positions1[i] == positions2[i], true);
    }
  });

  test('test movement category list', () {
    const serde = DbMovementCategoriesConverter();
    final cats = [MovementCategory.cardio, MovementCategory.strength];
    final serialized = serde.mapToSql(cats);
    final catsNew = serde.mapToDart(serialized);
    for (final c in cats) {
      expect(catsNew.contains(c), true);
    }
  });
}
