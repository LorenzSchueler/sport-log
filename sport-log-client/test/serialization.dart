import 'package:flutter_test/flutter_test.dart';
import 'package:sport_log/helpers/serialization/db_serialization.dart';
import 'package:sport_log/models/all.dart';

void main() {
  test('test position list', () {
    final positions1 = [
      Position(
        longitude: 32.234,
        latitude: 52.3423,
        elevation: 8849,
        distance: 1034,
        time: const Duration(seconds: 300),
      ),
      Position(
        longitude: 32.632,
        latitude: 52.3564,
        elevation: -56,
        distance: 2303,
        time: const Duration(seconds: 702),
      ),
      Position(
        longitude: 32.653,
        latitude: 52.4330,
        elevation: 0,
        distance: 2934,
        time: const Duration(seconds: 1100),
      ),
    ];

    final blob = DbPositionListConverter.mapToSql(positions1);

    final positions2 = DbPositionListConverter.mapToDart(blob);

    expect(positions2 != null, true);
    expect(positions1.length, positions2!.length);

    for (var i = 0; i < positions1.length; ++i) {
      expect(positions1[i] == positions2[i], true);
    }
  });
}
