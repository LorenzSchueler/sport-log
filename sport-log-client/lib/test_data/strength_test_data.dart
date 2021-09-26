import 'package:fixnum/fixnum.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/models/strength/all.dart';
import 'package:sport_log/models/movement/all.dart';
import 'package:faker/faker.dart';

final DateTime startDate = DateTime(2018, 4, 15);
final DateTime endDate = DateTime.now();

final random = faker.randomGenerator;

Future<List<StrengthSession>> generateStrengthSessions(Int64 userId) async {
  final movements = await AppDatabase.instance!.movements.getNonDeleted();

  final numberOfDays = endDate.difference(startDate).inDays + 1;
  final allDates = List.generate(
    numberOfDays,
    (index) => DateTime(startDate.year, startDate.month, startDate.day + index),
  );

  List<StrengthSession> result = [];

  for (final date in allDates) {
    for (final movement in movements) {
      for (int i = 0; i < 3; ++i) {
        if (random.integer(9) == 0) {
          result.add(StrengthSession(
            id: randomId(),
            userId: userId,
            datetime: DateTime(date.year, date.month, date.day,
                random.integer(24), random.integer(60), random.integer(60)),
            movementId: movement.id,
            interval: random.integer(2) == 0
                ? Duration(minutes: random.integer(90, min: 10)).inSeconds
                : null,
            comments: random.integer(2) == 0 ? faker.lorem.sentence() : null,
            deleted: false,
          ));
        }
      }
    }
  }
  return result;
}

int _generateCount(MovementDimension dim) {
  switch (dim) {
    case MovementDimension.reps:
      return random.integer(20, min: 1);
    case MovementDimension.cals:
      return random.integer(3000, min: 50);
    case MovementDimension.distance:
      return random.integer(42000, min: 20);
    case MovementDimension.time:
      return random.integer(10 * 60 * 1000, min: 10 * 1000);
  }
}

double? _generateWeight(MovementDimension dim) {
  if (dim != MovementDimension.reps) {
    return null;
  }
  if (random.integer(10) == 0) {
    return null;
  }
  return random.decimal(scale: 150, min: 1);
}

Future<List<StrengthSet>> generateStrengthSets() async {
  final sessions =
      await AppDatabase.instance!.strengthSessions.getNonDeletedDescriptions();

  List<StrengthSet> result = [];

  for (final session in sessions) {
    final int numberOfSets = random.integer(9, min: 1);
    for (int i = 0; i < numberOfSets; ++i) {
      result.add(StrengthSet(
        id: randomId(),
        strengthSessionId: session.id,
        setNumber: i,
        count: _generateCount(session.movement.dimension),
        weight: _generateWeight(session.movement.dimension),
        deleted: false,
      ));
    }
  }
  return result;
}
