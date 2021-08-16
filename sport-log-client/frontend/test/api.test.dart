
import 'package:flutter_test/flutter_test.dart';
import 'package:result_type/result_type.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/config.dart';

void testAction(Api api) {
  group('action test', () {
    test('get action providers', () async {
      expect((await api.getActionProviders()), isA<Success>());
    });
  });
}


void main() async {
  final Api api = Api.instance;
  api.urlBase = await Config.apiUrlBase;
  testAction(api);
}