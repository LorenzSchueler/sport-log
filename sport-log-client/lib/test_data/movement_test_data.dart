import 'package:faker/faker.dart';
import 'package:fixnum/fixnum.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/models/movement/movement.dart';

const int numberOfMovements = 15;

List<Movement> generateMovements(Int64 userId) {
  return List.generate(
    10,
    (index) => Movement(
      id: randomId(),
      userId: userId,
      name: faker.sport.name(),
      description: faker.lorem.sentence(),
      cardio: faker.randomGenerator.boolean(),
      unit: faker.randomGenerator.element(MovementUnit.values),
      deleted: false,
    ),
  );
}
