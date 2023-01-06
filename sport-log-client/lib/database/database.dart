import 'package:result_type/result_type.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/database/tables/all.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sqflite/sqflite.dart';

final _logger = Logger('DB');

enum DbErrorCode {
  uniqueViolation,
  unknown,
}

class DbError {
  DbError.uniqueViolation(this.table, this.columns)
      : dbErrorCode = DbErrorCode.uniqueViolation,
        databaseException = null;

  DbError.unknown(this.databaseException)
      : dbErrorCode = DbErrorCode.unknown,
        table = null,
        columns = null;

  factory DbError.fromDbException(DatabaseException databaseException) {
    if (databaseException.isUniqueConstraintError()) {
      try {
        final longColumns = databaseException
            .toString()
            .split("UNIQUE constraint failed: ")[1]
            .split(" (code 2067 ")[0]
            .split(", ");
        final table = longColumns[0].split(".")[0];
        final columns = longColumns.map((c) => c.split(".")[1]).toList();
        return DbError.uniqueViolation(table, columns);
      } on RangeError catch (_) {
        return DbError.unknown(databaseException);
      }
    } else {
      return DbError.unknown(databaseException);
    }
  }

  final DbErrorCode dbErrorCode;
  final String? table; // unique violation
  final List<String>? columns; // unique violation
  final DatabaseException? databaseException; // unknown

  @override
  String toString() {
    switch (dbErrorCode) {
      case DbErrorCode.uniqueViolation:
        return "An entry table $table with the same values for ${columns!.join(', ')} already exists.";
      case DbErrorCode.unknown:
        return databaseException != null
            ? "Unknown database error: $databaseException"
            : "Unknown database error";
    }
  }
}

class DbResult {
  DbResult.fromDbException(DatabaseException exception)
      : this.failure(DbError.fromDbException(exception));

  DbResult.failure(DbError dbError) : result = Failure(dbError);

  DbResult.success() : result = Success(null);

  DbResult.fromBool(bool condition)
      : result = condition ? Success(null) : Failure(DbError.unknown(null));

  Result<void, DbError> result;

  static Future<DbResult> catchError(Future<DbResult> Function() fn) async {
    try {
      return await fn();
    } on DatabaseException catch (e) {
      return DbResult.fromDbException(e);
    }
  }

  bool get isSuccess => result.isSuccess;

  bool get isFailure => result.isFailure;

  DbError get failure => result.failure;
}

class AppDatabase {
  AppDatabase._();

  static Database? _database;
  static Database? get database {
    return _database;
  }

  static Future<void> init() async {
    if (Config.instance.deleteDatabase) {
      await reset();
    } else {
      await open();
    }
  }

  static Future<void> open() async {
    _logger.i("Opening Database");
    _database = await databaseFactory.openDatabase(
      Config.databaseName,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON;'),
        onCreate: (db, version) async {
          for (final tableAccessor in tablesAccessors) {
            _logger.d("Creating table: ${tableAccessor.tableName}");
            for (final statement in tableAccessor.table.setupSql) {
              if (Config.instance.outputDbStatement) {
                _logger.d(statement);
              }
              await db.execute(statement);
            }
          }
        },
        onUpgrade: null,
        onDowngrade: null,
        onOpen: (db) => _logger.d("Database initialization done"),
      ),
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

  static List<TableAccessor> get tablesAccessors => [
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

  static final cardioSessionDescriptions = CardioSessionDescriptionTable();
  static final strengthSessionDescriptions = StrengthSessionDescriptionTable();
  static final movementDescriptions = MovementDescriptionTable();
}
