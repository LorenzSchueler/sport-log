import 'package:faker/faker.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:result_type/result_type.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/main.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/settings.dart';

void testUser(User user, User updatedUser) {
  group('User', () {
    test('create', () async {
      expect(await Api.user.postSingle(user), isA<Success>());
    });
    test('get', () async {
      expect(
        await Api.user.getSingle(user.username, user.password),
        isA<Success>(),
      );
    });
    test('update', () async {
      expect(await Api.user.putSingle(updatedUser), isA<Success>());
    });
    test('delete', () async {
      expect(await Api.user.deleteSingle(), isA<Success>());
    });
  });
}

void testAction() {
  test('get action providers', () async {
    expect(await Api.actionProviders.getMultiple(), isA<Success>());
  });
}

void testDiary(User sampleUser) {
  group('Diary', () {
    final diary = Diary(
      id: randomId(),
      userId: sampleUser.id,
      date: DateTime.now(),
      bodyweight: null,
      comments: "hallo",
      deleted: false,
    );

    test('create', () async {
      expect(await Api.diaries.postSingle(diary), isA<Success>());
    });
    test('get', () async {
      expect(await Api.diaries.getSingle(diary.id), isA<Success>());
    });
    test('get multiple', () async {
      expect(await Api.diaries.getMultiple(), isA<Success>());
    });
    test('update', () async {
      expect(
        await Api.diaries.putSingle(diary..date = DateTime.now()),
        isA<Success>(),
      );
    });
    test('set deleted', () async {
      expect(
        await Api.diaries.putSingle(diary..deleted = true),
        isA<Success>(),
      );
    });
  });
}

void testStrengthSession(User sampleUser) {
  group('Strength Session', () {
    final strengthSession = StrengthSession(
      id: randomId(),
      userId: sampleUser.id,
      datetime: DateTime.now(),
      movementId: Int64(1),
      interval: const Duration(minutes: 1),
      comments: null,
      deleted: false,
    );

    test('create', () async {
      expect(
        await Api.strengthSessions.postSingle(strengthSession),
        isA<Success>(),
      );
    });
    test('get', () async {
      expect(
        await Api.strengthSessions.getSingle(strengthSession.id),
        isA<Success>(),
      );
    });
    test('get multiple', () async {
      expect(await Api.strengthSessions.getMultiple(), isA<Success>());
    });
    test('update', () async {
      expect(
        await Api.strengthSessions
            .putSingle(strengthSession..comments = 'comments'),
        isA<Success>(),
      );
    });
    test('set deleted', () async {
      expect(
        await Api.strengthSessions.putSingle(strengthSession..deleted = true),
        isA<Success>(),
      );
    });
  });
}

void testActionRule(User sampleUser) {
  group('Action Rule', () {
    final actionRule = ActionRule(
      id: randomId(),
      userId: sampleUser.id,
      actionId: Int64(1),
      weekday: Weekday.monday,
      time: DateTime.now(),
      arguments: 'args',
      enabled: true,
      deleted: false,
    );

    test('create', () async {
      expect(await Api.actionRules.postSingle(actionRule), isA<Success>());
    });
    test('get', () async {
      expect(await Api.actionRules.getSingle(actionRule.id), isA<Success>());
    });
    test('get multiple', () async {
      expect(await Api.actionRules.getMultiple(), isA<Success>());
    });
    test('update', () async {
      expect(
        await Api.actionRules.putSingle(actionRule..time = DateTime.now()),
        isA<Success>(),
      );
    });
    test('set deleted', () async {
      expect(
        await Api.actionRules.putSingle(actionRule..deleted = true),
        isA<Success>(),
      );
    });
  });
}

Future<void> main() async {
  // ignore: no_leading_underscores_for_local_identifiers
  await for (final _ in initialize()) {}

  group("", () {
    // sample user group
    final sampleUser = User(
      id: randomId(),
      username: faker.internet.userName(),
      password: faker.internet.password(),
      email: faker.internet.email(),
    );

    setUpAll(() async {
      expect(await Api.user.postSingle(sampleUser), isA<Success>());
      Settings.instance.user = sampleUser;
    });

    tearDownAll(() async {
      expect(await Api.user.deleteSingle(), isA<Success>());
    });

    testAction();
    testDiary(sampleUser);
    testStrengthSession(sampleUser);
    //testActionRule(sampleUser);
  });

  group("", () {
    // new user group
    final user = User(
      id: randomId(),
      username: faker.internet.userName(),
      password: faker.internet.password(),
      email: faker.internet.email(),
    );

    setUpAll(() {
      Settings.instance.user = user;
    });

    final updatedUser = user
      ..username = faker.internet.userName()
      ..password = faker.internet.password()
      ..email = faker.internet.email();

    testUser(user, updatedUser);
  });
}
