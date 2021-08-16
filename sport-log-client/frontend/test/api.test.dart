
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:result_type/result_type.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/models/all.dart';
import 'package:faker/faker.dart';


final User sampleUser = User(
    id: Int64(1),
    username: "user1",
    password: "user1-passwd",
    email: "email1"
);

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
  api.setCurrentUser(sampleUser);
  test('get action providers', () async {
    expect((await api.getActionProviders()), isA<Success>());
  });
}

void main() async {
  final Api api = Api.instance;
  await api.init();

  testUser(api);
  testAction(api);
}