import 'package:faker/faker.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_log/api/accessors/action_api.dart';
import 'package:sport_log/api/accessors/diary_api.dart';
import 'package:sport_log/api/accessors/strength_api.dart';
import 'package:sport_log/api/accessors/user_api.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/main.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/settings.dart';

void testUser(User user, User updatedUser) {
  group('User', () {
    test('create', () async {
      assert((await UserApi().postSingle(user)).isSuccess);
    });
    test('get', () async {
      assert(
        (await UserApi().getSingle(user.username, user.password)).isSuccess,
      );
    });
    test('update', () async {
      assert((await UserApi().putSingle(updatedUser)).isSuccess);
    });
    test('delete', () async {
      assert((await UserApi().deleteSingle()).isSuccess);
    });
  });
}

void testAction() {
  test('get action providers', () async {
    assert((await ActionProviderApi().getMultiple()).isSuccess);
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
      assert((await DiaryApi().postSingle(diary)).isSuccess);
    });
    test('get', () async {
      assert((await DiaryApi().getSingle(diary.id)).isSuccess);
    });
    test('get multiple', () async {
      assert((await DiaryApi().getMultiple()).isSuccess);
    });
    test('update', () async {
      assert(
        (await DiaryApi().putSingle(diary..date = DateTime.now())).isSuccess,
      );
    });
    test('set deleted', () async {
      assert((await DiaryApi().putSingle(diary..deleted = true)).isSuccess);
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
      assert(
        (await StrengthSessionApi().postSingle(strengthSession)).isSuccess,
      );
    });
    test('get', () async {
      assert(
        (await StrengthSessionApi().getSingle(strengthSession.id)).isSuccess,
      );
    });
    test('get multiple', () async {
      assert((await StrengthSessionApi().getMultiple()).isSuccess);
    });
    test('update', () async {
      assert(
        (await StrengthSessionApi()
                .putSingle(strengthSession..comments = 'comments'))
            .isSuccess,
      );
    });
    test('set deleted', () async {
      assert(
        (await StrengthSessionApi().putSingle(strengthSession..deleted = true))
            .isSuccess,
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
      assert((await ActionRuleApi().postSingle(actionRule)).isSuccess);
    });
    test('get', () async {
      assert((await ActionRuleApi().getSingle(actionRule.id)).isSuccess);
    });
    test('get multiple', () async {
      assert((await ActionRuleApi().getMultiple()).isSuccess);
    });
    test('update', () async {
      assert(
        (await ActionRuleApi().putSingle(actionRule..time = DateTime.now()))
            .isSuccess,
      );
    });
    test('set deleted', () async {
      assert(
        (await ActionRuleApi().putSingle(actionRule..deleted = true)).isSuccess,
      );
    });
  });
}

Future<void> main() async {
  await initialize().drain<void>();

  group("", () {
    // sample user group
    final sampleUser = User(
      id: randomId(),
      username: faker.internet.userName(),
      password: faker.internet.password(),
      email: faker.internet.email(),
    );

    setUpAll(() async {
      assert((await UserApi().postSingle(sampleUser)).isSuccess);
      await Settings.instance.setUser(sampleUser);
    });

    tearDownAll(() async {
      assert((await UserApi().deleteSingle()).isSuccess);
    });

    testAction();
    testDiary(sampleUser);
    testStrengthSession(sampleUser);
    testActionRule(sampleUser);
  });

  group("", () {
    // new user group
    final user = User(
      id: randomId(),
      username: faker.internet.userName(),
      password: faker.internet.password(),
      email: faker.internet.email(),
    );

    setUpAll(() async {
      await Settings.instance.setUser(user);
    });

    final updatedUser = user
      ..username = faker.internet.userName()
      ..password = faker.internet.password()
      ..email = faker.internet.email();

    testUser(user, updatedUser);
  });
}
