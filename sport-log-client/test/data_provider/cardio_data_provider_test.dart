import 'package:flutter_test/flutter_test.dart';
import 'package:sport_log/data_provider/data_providers/cardio_data_provider.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/database/tables/cardio_tables.dart';
import 'package:sport_log/database/tables/movement_table.dart';
import 'package:sport_log/models/cardio/all.dart';
import 'package:sport_log/models/movement/movement.dart';

import '../test_setup.dart';

void main() {
  var notified = 0;
  void countNotification() => notified++;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initConfig();
    await initDatabaseFactory();
    CardioSessionDataProvider().addListener(countNotification);
  });

  setUp(() async {
    notified = 0;
    await AppDatabase.reset();
  });

  Future<(Route, CardioSession)> createRouteAndSession({
    bool sessionDeleted = false,
    SyncStatus sessionSyncStatus = SyncStatus.synchronized,
  }) async {
    final movement = Movement.defaultValue()..name = 'movement';
    await MovementTable().createSingle(movement);
    final route = Route.defaultValue()
      ..name = 'route'
      ..distance = 1000;
    await RouteTable().createSingle(route);
    final session = CardioSession.defaultValue(movement.id)
      ..routeId = route.id
      ..deleted = sessionDeleted;
    await CardioSessionTable().createSingle(session);
    await CardioSessionTable().setSyncStatus(session, sessionSyncStatus);
    return (route, session);
  }

  for (final (name, sessionDeleted, syncStatus, routeKept, expectedSyncStatus)
      in [
        (
          'clears the route of a synchronized session and marks it updated',
          false,
          SyncStatus.synchronized,
          false,
          SyncStatus.updated,
        ),
        (
          'clears the route of a created session',
          false,
          SyncStatus.created,
          false,
          SyncStatus.created,
        ),
        (
          'keeps the route of a deleted session',
          true,
          SyncStatus.synchronized,
          true,
          SyncStatus.synchronized,
        ),
      ]) {
    test('deleting a route $name', () async {
      final (route, session) = await createRouteAndSession(
        sessionDeleted: sessionDeleted,
        sessionSyncStatus: syncStatus,
      );

      await RouteDataProvider().deleteSingle(route);

      expect(
        (await CardioSessionTable().getById(session.id))!.routeId,
        routeKept ? route.id : isNull,
      );
      expect(
        await CardioSessionTable().getSyncStatus(session),
        expectedSyncStatus,
      );
      expect(notified, 1);
    });
  }

  for (final (name, routeDeleted, expectedNotified) in [
    ('clears the route of the sessions if deleted', true, 1),
    ('keeps the route of the sessions if live', false, 0),
  ]) {
    test('downloading a route $name', () async {
      final (route, session) = await createRouteAndSession();
      route.deleted = routeDeleted;

      await RouteDataProvider().upsertMultiple([route], synchronized: true);

      expect(
        (await CardioSessionTable().getById(session.id))!.routeId,
        routeDeleted ? isNull : route.id,
      );
      expect(notified, expectedNotified);
    });
  }
}
