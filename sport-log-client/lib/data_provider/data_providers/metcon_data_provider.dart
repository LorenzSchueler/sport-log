import 'package:sport_log/database/database.dart';

import '../data_provider.dart';

class MetconDataProvider extends DataProvider {
  final AppDatabase? database = AppDatabase.instance;

  @override
  Future<void> pushToServer() async {}
}
