import 'dart:io';

import 'package:sport_log/config.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/account_data/account_data.dart';
import 'package:sqflite/sqflite.dart';

import 'tables/all.dart';

final _logger = Logger('DB');

class AppDatabase {
  static final AppDatabase? instance =
      Config.isAndroid || Config.isIOS ? AppDatabase._() : null;

  AppDatabase._();

  Future<void> init() async {
    const fileName = Config.databaseName;
    if (Config.deleteDatabase) {
      final File databaseFile = File(await getDatabasesPath() + '/' + fileName);
      if (await databaseFile.exists()) {
        _logger.i('Clean start on: deleting existing database...');
        await databaseFile.delete();
      }
    }
    String version = '';
    await openDatabase(fileName,
        version: 1,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON;'),
        onCreate: (db, version) async {
          List<String> sql = [];
          for (final table in allTables) {
            sql += table.setupSql;
          }
          for (final statement in sql) {
            _logger.d(statement);
            db.execute(statement);
          }
        },
        onOpen: (db) async {
          for (final table in allTables) {
            table.setDatabase(db);
          }
          version = (await db.rawQuery('select sqlite_version() AS version'))
              .first['version'] as String;
        });
    _logger.d("Database initialization done (sqlite version $version).");
  }

  Future<void> upsertAccountData(AccountData data,
      {required bool synchronized}) async {
    diaries.upsertMultiple(data.diaries, synchronized: synchronized);
    wods.upsertMultiple(data.wods, synchronized: synchronized);
    movements.upsertMultiple(data.movements, synchronized: synchronized);
    metcons.upsertMultiple(data.metcons, synchronized: synchronized);
    metconMovements.upsertMultiple(data.metconMovements,
        synchronized: synchronized);
    metconSessions.upsertMultiple(data.metconSessions,
        synchronized: synchronized);
    routes.upsertMultiple(data.routes, synchronized: synchronized);
    cardioSessions.upsertMultiple(data.cardioSessions,
        synchronized: synchronized);
    platforms.upsertMultiple(data.platforms, synchronized: synchronized);
    platformCredentials.upsertMultiple(data.platformCredentials,
        synchronized: synchronized);
    actionProviders.upsertMultiple(data.actionProviders,
        synchronized: synchronized);
    actions.upsertMultiple(data.actions, synchronized: synchronized);
    actionRules.upsertMultiple(data.actionRules, synchronized: synchronized);
    actionEvents.upsertMultiple(data.actionEvents, synchronized: synchronized);
  }

  final movements = MovementTable();
  final metcons = MetconTable();
  final metconMovements = MetconMovementTable();
  final metconSessions = MetconSessionTable();
  final routes = RouteTable();
  final cardioSessions = CardioSessionTable();
  final strengthSets = StrengthSetTable();
  final strengthSessions = StrengthSessionTable();
  final platforms = PlatformTable();
  final platformCredentials = PlatformCredentialTable();
  final actionProviders = ActionProviderTable();
  final actions = ActionTable();
  final actionRules = ActionRuleTable();
  final actionEvents = ActionEventTable();
  final diaries = DiaryTable();
  final wods = WodTable();

  List<DbAccessor> get allTables => [
        movements,
        metcons,
        metconMovements,
        metconSessions,
        routes,
        cardioSessions,
        strengthSets,
        strengthSessions,
        platforms,
        platformCredentials,
        actionProviders,
        actions,
        actionRules,
        actionEvents,
        diaries,
        wods,
      ];
}
