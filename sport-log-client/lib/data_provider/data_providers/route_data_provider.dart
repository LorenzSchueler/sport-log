import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/models/cardio/all.dart';

class RouteDataProvider {
  final DbAccessor<Route> routeDb = AppDatabase.instance!.routes;

  // final ApiAccessor<Route> routeApi = Api.routes;

  Future<List<Route>> getNonDeleted() async {
    return (await routeDb.getNonDeleted());
  }
}
