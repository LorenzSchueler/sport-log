import 'package:faker/faker.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:result_type/result_type.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/all.dart';

final logger = Logger('TEST');

final User sampleUser = User(
    id: Int64(1), username: "user1", password: "user1-passwd", email: "email1");

void testUser(Api api) {
  test('user test', () async {
    final user = User(
      id: randomId(),
      username: faker.internet.userName(),
      password: faker.internet.password(),
      email: faker.internet.email(),
    );

    expect(await api.createUser(user), isA<Success>());
    expect(await api.getUser(user.username, user.password), isA<Success>());

    final updatedUser = User(
      id: user.id,
      username: faker.internet.userName(),
      password: faker.internet.password(),
      email: faker.internet.email(),
    );

    expect(await api.updateUser(updatedUser), isA<Success>());
    expect(await api.deleteUser(), isA<Success>());
  });
}

void testAction(Api api) async {
  test('get action providers', () async {
    api.setCurrentUser(sampleUser);
    expect(await api.getActionProviders(), isA<Success>());
  });
}

void testDiary(Api api) async {
  test('test diary', () async {
    final diary = Diary(
      id: randomId(),
      userId: sampleUser.id,
      date: faker.date.dateTime(),
      bodyweight: null,
      comments: "hallo",
      deleted: false,
    );

    api.setCurrentUser(sampleUser);
    expect(await api.createDiary(diary), isA<Success>());
    expect(await api.getDiaries(), isA<Success>());
    final date = faker.date.dateTime();
    diary.date = DateTime(date.year, date.month, date.day);
    expect(await api.updateDiary(diary), isA<Success>());
    final result = await api.getDiary(diary.id);
    expect(result, isA<Success>());
    expect(result.success.date, diary.date);
    expect(await api.updateDiary(diary..deleted = true), isA<Success>());
  });
}

void testStrengthSession(Api api) async {
  test('test strength session', () async {
    final strengthSession = StrengthSession(
      id: randomId(),
      userId: sampleUser.id,
      datetime: DateTime.now(),
      movementId: Int64(1),
      movementUnit: MovementUnit.reps,
      interval: 10,
      comments: null,
      deleted: false,
    );

    api.setCurrentUser(sampleUser);
    expect(await api.createStrengthSession(strengthSession), isA<Success>());
    expect(await api.getStrengthSessions(), isA<Success>());
    expect(
        await api.updateStrengthSession(
            strengthSession..movementUnit = MovementUnit.cal),
        isA<Success>());
    expect(await api.updateStrengthSession(strengthSession..deleted = true),
        isA<Success>());
  });
}

void testActionRule(Api api) async {
  test('test action rule', () async {
    final actionRule = ActionRule(
      id: randomId(),
      userId: sampleUser.id,
      actionId: Int64(1),
      weekday: Weekday.values[faker.randomGenerator.integer(7)],
      time: DateTime(
        2021,
        8,
        17,
        faker.randomGenerator.integer(24),
        faker.randomGenerator.integer(60),
        faker.randomGenerator.integer(60),
      ),
      arguments: 'args',
      enabled: true,
      deleted: false,
    );
    api.setCurrentUser(sampleUser);
    expect(await api.createActionRule(actionRule), isA<Success>());
    expect(await api.getActionRules(), isA<Success>());
    actionRule.time = DateTime(
      2021,
      8,
      17,
      faker.randomGenerator.integer(24),
      faker.randomGenerator.integer(60),
      faker.randomGenerator.integer(60),
    );
    logger.i(actionRule.time.toString());
    expect(await api.updateActionRule(actionRule), isA<Success>());
    final result = await api.getActionRule(actionRule.id);
    expect(result, isA<Success>());
    logger.i(result.success.time.toString());
    // expect(result.success.time, actionRule.time);
    expect(
        await api.updateActionRule(actionRule..deleted = true), isA<Success>());
  });
}

void main() async {
  final Api api = await Api.instance;

  testUser(api);
  testAction(api);
  testDiary(api);
  testStrengthSession(api);
  testActionRule(api);
}
