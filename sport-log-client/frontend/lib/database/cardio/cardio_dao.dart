
import 'package:fixnum/fixnum.dart';
import 'package:moor/moor.dart';
import 'package:result_type/result_type.dart';
import 'package:sport_log/database/cardio/cardio_tables.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/models/cardio/all.dart';
import 'package:sport_log/models/cardio/cardio_session_description.dart';

part 'cardio_dao.g.dart';

@UseDao(
  tables: [CardioSessions, Routes],
  include: {'cardio.moor'},
)
class CardioDao extends DatabaseAccessor<Database> with _$CardioDaoMixin {
  CardioDao(Database attachedDatabase) : super(attachedDatabase);

  Future<Result<void, DbException>> createCardioSession(
      CardioSession cs) async {
    if (!cs.validateOnUpdate()) {
      return Failure(DbException.validationFailed);
    }
    await into(cardioSessions).insert(cs);
    return Success(null);
  }

  Future<Result<void, DbException>> createRoute(Route route) async {
    if (!route.validateOnUpdate()) {
      return Failure(DbException.validationFailed);
    }
    await into(routes).insert(route);
    return Success(null);
  }

  Future<void> deleteCardioSession(Int64 id) async {
    await (update(cardioSessions)
      ..where((cs) => cs.id.equals(id.toInt())
        & cs.deleted.not())
    ).write(const CardioSessionsCompanion(deleted: Value(true)));
  }

  Future<Result<void, DbException>> deleteRoute(Int64 id) async {
    if ((await _cardioSessionWithRouteExists(id.toInt())
        .getSingleOrNull()) != null) {
      return Failure(DbException.hasDependency);
    }
    await (update(routes)
      ..where((r) => r.id.equals(id.toInt())
          & r.deleted.not())
    ).write(const RoutesCompanion(deleted: Value(true)));
    return Success(null);
  }

  Future<Result<void, DbException>> updateCardioSession(
      CardioSession cardioSession) async {
    if (!cardioSession.validateOnUpdate()) {
      return Failure(DbException.validationFailed);
    }
    await (update(cardioSessions)
      ..where((cs) => cs.id.equals(cardioSession.id.toInt())
        & cs.deleted.not())
    ).write(cardioSession);

    return Success(null);
  }

  Future<List<CardioSessionDescription>> getAllCardioSessions() async {
    final sessions = await (select(cardioSessions)
      ..where((cs) => cs.deleted.not())
    ).get();
    return Future.wait(sessions.map((s) async =>
      CardioSessionDescription(
          cardioSession: s,
          route: s.routeId == null ? null : await _getRoute(s.routeId!)
      )
    ));
  }

  Future<Route> _getRoute(Int64 id) async {
    return await (select(routes)
      ..where((r) => r.id.equals(id.toInt()) & r.deleted.not())
    ).getSingle();
  }

  Future<List<Route>> getAllRoutes() async {
    return (select(routes)
      ..where((r) => r.deleted.not())
    ).get();
  }
}