import 'package:sport_log/config.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/database/tables/all.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sqflite/sqflite.dart';

final _logger = Logger('DB');

class AppDatabase {
  AppDatabase._();

  static Database? _database;
  static Database? get database {
    return _database;
  }

  static Future<void> init() async {
    if (Config.deleteDatabase) {
      await reset();
    }
    await open();
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

  static Future<void> reset() async {
    _logger.i("Deleting Database");
    await deleteDatabase(Config.databaseName);
    _database = null;
    _logger.i('Database deleted');
    await open();
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

  static List<TableAccessor> get allTables => [
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
