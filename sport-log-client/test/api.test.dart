import 'package:faker/faker.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:result_type/result_type.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/main.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/settings.dart';

final _logger = Logger('TEST');

final User sampleUser = User(
    id: Int64(1), username: "user1", password: "user1-passwd", email: "email1");

void testUser() {
  test('user test', () async {
    final user = User(
      id: randomId(),
      username: faker.internet.userName(),
      password: faker.internet.password(),
      email: faker.internet.email(),
    );

    expect(await Api.user.postSingle(user), isA<Success>());
    expect(
        await Api.user.getSingle(user.username, user.password), isA<Success>());

    final updatedUser = User(
      id: user.id,
      username: faker.internet.userName(),
      password: faker.internet.password(),
      email: faker.internet.email(),
    );

    expect(await Api.user.putSingle(updatedUser), isA<Success>());
    expect(await Api.user.deleteSingle(), isA<Success>());
  });
}

void testAction() async {
  test('get action providers', () async {
    Settings.user = sampleUser;
    expect(await Api.actionProviders.getMultiple(), isA<Success>());
  });
}

void testDiary() async {
  test('test diary', () async {
    final diary = Diary(
      id: randomId(),
      userId: sampleUser.id,
      date: faker.date.dateTime(),
      bodyweight: null,
      comments: "hallo",
      deleted: false,
    );

    Settings.user = sampleUser;
    expect(await Api.diaries.postSingle(diary), isA<Success>());
    expect(await Api.diaries.getMultiple(), isA<Success>());
    final date = faker.date.dateTime();
    diary.date = DateTime(date.year, date.month, date.day);
    expect(await Api.diaries.putSingle(diary), isA<Success>());
    final result = await Api.diaries.getSingle(diary.id);
    expect(result, isA<Success>());
    expect(result.success.date, diary.date);
    expect(await Api.diaries.putSingle(diary..deleted = true), isA<Success>());
  });
}

void testStrengthSession() async {
  test('test strength session', () async {
    final strengthSession = StrengthSession(
      id: randomId(),
      userId: sampleUser.id,
      datetime: DateTime.now(),
      movementId: Int64(1),
      interval: const Duration(minutes: 1),
      comments: null,
      deleted: false,
    );

    Settings.user = sampleUser;
    expect(
        await Api.strengthSessions.postSingle(strengthSession), isA<Success>());
    expect(await Api.strengthSessions.getMultiple(), isA<Success>());
    expect(
        await Api.strengthSessions
            .putSingle(strengthSession..comments = 'comments'),
        isA<Success>());
    expect(
        await Api.strengthSessions.putSingle(strengthSession..deleted = true),
        isA<Success>());
  });
}

void testActionRule() async {
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
    Settings.user = sampleUser;
    expect(await Api.actionRules.postSingle(actionRule), isA<Success>());
    expect(await Api.actionRules.getMultiple(), isA<Success>());
    actionRule.time = DateTime(
      2021,
      8,
      17,
      faker.randomGenerator.integer(24),
      faker.randomGenerator.integer(60),
      faker.randomGenerator.integer(60),
    );
    _logger.i(actionRule.time.toString());
    expect(await Api.actionRules.putSingle(actionRule), isA<Success>());
    final result = await Api.actionRules.getSingle(actionRule.id);
    expect(result, isA<Success>());
    _logger.i(result.success.time.toString());
    // expect(result.success.time, actionRule.time);
    expect(await Api.actionRules.putSingle(actionRule..deleted = true),
        isA<Success>());
  });
}

void main() async {
  await initialize(doDownSync: false);

  testUser();
  testAction();
  testDiary();
  testStrengthSession();
  testActionRule();
}
