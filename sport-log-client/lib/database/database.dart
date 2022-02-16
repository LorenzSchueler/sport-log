import 'package:sport_log/config.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/account_data/account_data.dart';
import 'package:sqflite/sqflite.dart';

import 'tables/all.dart';

final _logger = Logger('DB');

class AppDatabase {
  AppDatabase._();

  static Database? _database;
  static Database? get database {
    return _database;
  }

  static Future<void> init() async {
    if (Config.deleteDatabase) {
      await delete();
      await open();
    }
    // db is opened in Account.login and Account.register and deleted in Account.logout
  }

  static Future<void> open() async {
    _logger.i("Opening Database");
    _database = await openDatabase(
      Config.databaseName,
      version: 1,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON;'),
      onCreate: (db, version) async {
        for (final table in allTables) {
          _logger.d("Creating table: ${table.tableName}");
          for (final statement in table.setupSql) {
            if (Config.outputDbStatement) {
              _logger.d(statement);
            }
            db.execute(statement);
          }
        }
      },
      onUpgrade: null, // TODO
      onDowngrade: null, // TODO
      onOpen: (db) => _logger.d("Database initialization done"),
    );
    _logger.i("Database ready");
  }

  static Future<void> delete() async {
    _logger.i("Deleting Database");
    await deleteDatabase(Config.databaseName);
    _database = null;
    _logger.i('Database deleted');
  }

  static Future<void> upsertAccountData(AccountData data,
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

  static final diaries = DiaryTable();
  static final wods = WodTable();
  static final movements = MovementTable();
  static final metcons = MetconTable();
  static final metconMovements = MetconMovementTable();
  static final metconSessions = MetconSessionTable();
  static final routes = RouteTable();
  static final cardioSessions = CardioSessionTable();
  static final strengthSessions = StrengthSessionTable();
  static final strengthSets = StrengthSetTable();
  static final platforms = PlatformTable();
  static final platformCredentials = PlatformCredentialTable();
  static final actionProviders = ActionProviderTable();
  static final actions = ActionTable();
  static final actionRules = ActionRuleTable();
  static final actionEvents = ActionEventTable();

  static List<DbAccessor> get allTables => [
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
