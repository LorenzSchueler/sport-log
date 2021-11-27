import 'package:sport_log/api/api.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/models/cardio/all.dart';

class RouteDataProvider {
  final DbAccessor<Route> routeDb = AppDatabase.instance!.routes;

  // final ApiAccessor<Route> routeApi = Api.instance.routes;

  @override
  Future<List<Route>> getNonDeleted() async {
    return (await routeDb.getNonDeleted());
  }
}
