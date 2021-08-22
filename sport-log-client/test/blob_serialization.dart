
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_log/helpers/db_serialization.dart';
import 'package:sport_log/models/all.dart';

void main() {
  test('test position list', () {
    List<Position> positions1 = [
      Position(longitude: 32.234, latitude: 52.3423, elevation: 24.11, distance: 1034, time: 300),
      Position(longitude: 32.632, latitude: 52.3564, elevation: 56.23, distance: 2303, time: 702),
      Position(longitude: 32.653, latitude: 52.4330, elevation: 33.69, distance: 2934, time: 1100),
    ];

    final blob = const DbPositionListConverter().mapToSql(positions1);

    final positions2 = const DbPositionListConverter().mapToDart(blob);

    expect(positions2 != null, true);
    expect(positions1.length, positions2!.length);

    for (int i = 0; i < positions1.length; ++i) {
      expect(positions1[i] == positions2[i], true);
    }
  });
}