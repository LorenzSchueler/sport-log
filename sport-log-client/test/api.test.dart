import 'package:faker/faker.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:result_type/result_type.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/user_state.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/main.dart';
import 'package:sport_log/models/all.dart';

final _logger = Logger('TEST');

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

    expect(await api.user.postSingle(user), isA<Success>());
    expect(
        await api.user.getSingle(user.username, user.password), isA<Success>());

    final updatedUser = User(
      id: user.id,
      username: faker.internet.userName(),
      password: faker.internet.password(),
      email: faker.internet.email(),
    );

    expect(await api.user.putSingle(updatedUser), isA<Success>());
    expect(await api.user.deleteSingle(), isA<Success>());
  });
}

void testAction(Api api) async {
  test('get action providers', () async {
    UserState.instance.setUser(sampleUser);
    expect(await api.actionProviders.getMultiple(), isA<Success>());
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

    UserState.instance.setUser(sampleUser);
    expect(await api.diaries.postSingle(diary), isA<Success>());
    expect(await api.diaries.getMultiple(), isA<Success>());
    final date = faker.date.dateTime();
    diary.date = DateTime(date.year, date.month, date.day);
    expect(await api.diaries.putSingle(diary), isA<Success>());
    final result = await api.diaries.getSingle(diary.id);
    expect(result, isA<Success>());
    expect(result.success.date, diary.date);
    expect(await api.diaries.putSingle(diary..deleted = true), isA<Success>());
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

    UserState.instance.setUser(sampleUser);
    expect(
        await api.strengthSessions.postSingle(strengthSession), isA<Success>());
    expect(await api.strengthSessions.getMultiple(), isA<Success>());
    expect(
        await api.strengthSessions
            .putSingle(strengthSession..movementUnit = MovementUnit.cals),
        isA<Success>());
    expect(
        await api.strengthSessions.putSingle(strengthSession..deleted = true),
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
    UserState.instance.setUser(sampleUser);
    expect(await api.actionRules.postSingle(actionRule), isA<Success>());
    expect(await api.actionRules.getMultiple(), isA<Success>());
    actionRule.time = DateTime(
      2021,
      8,
      17,
      faker.randomGenerator.integer(24),
      faker.randomGenerator.integer(60),
      faker.randomGenerator.integer(60),
    );
    _logger.i(actionRule.time.toString());
    expect(await api.actionRules.putSingle(actionRule), isA<Success>());
    final result = await api.actionRules.getSingle(actionRule.id);
    expect(result, isA<Success>());
    _logger.i(result.success.time.toString());
    // expect(result.success.time, actionRule.time);
    expect(await api.actionRules.putSingle(actionRule..deleted = true),
        isA<Success>());
  });
}

void main() async {
  await initialize(doDownSync: false);
  final Api api = Api.instance;

  testUser(api);
  testAction(api);
  testDiary(api);
  testStrengthSession(api);
  testActionRule(api);
}
