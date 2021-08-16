
import 'dart:developer';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:result_type/result_type.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/api/api_error.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/models/all.dart';
import 'package:faker/faker.dart';


void testUser(Api api) {
  group('user test', () {
    final user = User(
      id: randomId(),
      username: faker.internet.userName(),
      password: faker.internet.password(),
      email: faker.internet.email(),
    );

    test('create user', () async {
      expect(await api.createUser(user), isA<Success>());
    });

    test('get user', () async {
      expect(await api.getUser(user.email, user.password), isA<Success>());
    });

    user.email = faker.internet.email();
    user.password = faker.internet.password();
    user.username = faker.internet.userName();

    test('update user', () async {
      expect(await api.updateUser(user), isA<Success>());
    });

    test('delete user', () async {
      expect(await api.deleteUser(), isA<Success>());
    });
  });
}

void testAction(Api api) {
  group('action test', () {
    test('get action providers', () async {
      expect((await api.getActionProviders()), isA<Success>());
    });
  });
}


void main() async {
  final Api api = Api.instance;
  await api.init();

  // testUser(api);

  final result = await api.getUser('user2', 'user2-passwd');
  if (result.isFailure) {
    stderr.writeln(result.failure);
  }
  assert(result.isSuccess);

  // testAction(api);

  assert((await api.deleteUser()).isSuccess);
}