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
    const dbFileName = Config.databaseName;
    if (Config.deleteDatabase) {
      deleteDatabase(dbFileName);
      _logger.i('Deleting existing database...');
      //final File databaseFile = File(await getDatabasesPath() + '/' + dbFileName);
      //if (await databaseFile.exists()) {
      //_logger.i('Clean start on: deleting existing database...');
      //await databaseFile.delete();
      //}
    }
    await openDatabase(
      dbFileName,
      version: 1,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON;'),
      onCreate: (db, version) async {
        for (final table in allTables) {
          _logger.d("Creating table: ${table.tableName}");
          for (final statement in table.setupSql) {
            _logger.d(statement);
            db.execute(statement);
          }
        }
      },
      onUpgrade: null, // TODO
      onDowngrade: null, // TODO
      onOpen: (db) async {
        for (final table in allTables) {
          table.setDatabase(db);
        }
        _logger.d("Database initialization done");
      },
    );
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
    strengthSessions.upsertMultiple(data.strengthSessions,
        synchronized: synchronized);
    strengthSets.upsertMultiple(data.strengthSets, synchronized: synchronized);
    platforms.upsertMultiple(data.platforms, synchronized: synchronized);
    platformCredentials.upsertMultiple(data.platformCredentials,
        synchronized: synchronized);
    actionProviders.upsertMultiple(data.actionProviders,
        synchronized: synchronized);
    actions.upsertMultiple(data.actions, synchronized: synchronized);
    actionRules.upsertMultiple(data.actionRules, synchronized: synchronized);
    actionEvents.upsertMultiple(data.actionEvents, synchronized: synchronized);
  }

  final diaries = DiaryTable();
  final wods = WodTable();
  final movements = MovementTable();
  final metcons = MetconTable();
  final metconMovements = MetconMovementTable();
  final metconSessions = MetconSessionTable();
  final routes = RouteTable();
  final cardioSessions = CardioSessionTable();
  final strengthSessions = StrengthSessionTable();
  final strengthSets = StrengthSetTable();
  final platforms = PlatformTable();
  final platformCredentials = PlatformCredentialTable();
  final actionProviders = ActionProviderTable();
  final actions = ActionTable();
  final actionRules = ActionRuleTable();
  final actionEvents = ActionEventTable();

  List<DbAccessor> get allTables => [
        diaries,
        wods,
        movements,
        metcons,
        metconMovements,
        metconSessions,
        routes,
        cardioSessions,
        strengthSessions,
        strengthSets,
        platforms,
        platformCredentials,
        actionProviders,
        actions,
        actionRules,
        actionEvents,
      ];
}
