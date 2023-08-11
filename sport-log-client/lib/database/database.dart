import 'package:result_type/result_type.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/database/tables/action_tables.dart';
import 'package:sport_log/database/tables/cardio_tables.dart';
import 'package:sport_log/database/tables/diary_table.dart';
import 'package:sport_log/database/tables/metcon_tables.dart';
import 'package:sport_log/database/tables/movement_table.dart';
import 'package:sport_log/database/tables/platform_tables.dart';
import 'package:sport_log/database/tables/strength_tables.dart';
import 'package:sport_log/database/tables/wod_table.dart';
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
    return switch (dbErrorCode) {
      DbErrorCode.uniqueViolation =>
        "An entry in table $table with the same values for ${columns!.join(', ')} already exists.",
      DbErrorCode.unknown => databaseException != null
          ? "Unknown database error: $databaseException"
          : "Unknown database error",
    };
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

  // ignore: long-method
  static Future<void> open() async {
    _logger.i("opening database");
    _database = await databaseFactory.openDatabase(
      Config.databaseName,
      options: OpenDatabaseOptions(
        version: 2,
        onConfigure: (db) => db.execute("pragma foreign_keys = ON;"),
        onCreate: (db, version) async {
          for (final table in _tables) {
            _logger.i("creating table: ${table.tableName}");
            for (final statement in table.table.setupSql) {
              if (Config.instance.outputDbStatement) {
                _logger.t(statement);
              }
              await db.execute(statement);
            }
          }
          for (final statement in eormTable.setupSql) {
            if (Config.instance.outputDbStatement) {
              _logger.t(statement);
            }
            await db.execute(statement);
          }
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2 && newVersion >= 2) {
            final optionalUserIdTables = [
              (Tables.movement, Columns.isDefaultMovement),
              (Tables.metcon, Columns.isDefaultMetcon),
            ];
            for (final (table, column) in optionalUserIdTables) {
              await db.execute(
                "alter table $table add column $column bool not null default 0 check($column in (0, 1));",
              );
              await db.execute(
                "update table $table set $column = user_id is null;",
              );
            }
            final userIdTables = [
              Tables.actionEvent,
              Tables.actionRule,
              Tables.cardioSession,
              Tables.route,
              Tables.diary,
              Tables.metconSession,
              Tables.metcon,
              Tables.movement,
              Tables.platformCredential,
              Tables.strengthSession,
              Tables.wod,
            ];
            for (final table in userIdTables) {
              await db.execute("alter table $table drop column user_id;");
            }

            await db.execute(
              "alter table ${Tables.action} drop column create_before;",
            );
            await db.execute(
              "alter table ${Tables.action} drop column delete_after;",
            );
            await db.execute(
              "alter table ${Tables.actionProvider} drop column password;",
            );

            // alter tables/ indices by creating new table and copying all data over
            await db.execute("pragma foreign_keys=off;");
            final recreateTables = <(String, TableAccessor)>[
              (
                Tables.cardioSession,
                CardioSessionTable()
              ), // drop index & drop not null on distance
              (Tables.metconSession, MetconSessionTable()), // drop index
              (Tables.strengthSession, StrengthSessionTable()), // drop index
              (Tables.route, RouteTable()), // drop not null on distance
            ];
            for (final (table, tableAccessor) in recreateTables) {
              await db.transaction((txn) async {
                final oldTable = "old_$table";
                await txn.execute("alter table $table rename to $oldTable;");
                for (final statement in tableAccessor.table.setupSql) {
                  await txn.execute(statement);
                }
                await txn
                    .execute("insert into $table select * from $oldTable;");
                await txn.execute("drop table $oldTable;");
              });
            }
            await db.execute("pragma foreign_keys=on;");
          }
          _logger.i("database migration done");
        },
        //onDowngrade: null,
        onOpen: (db) => _logger.i("database initialization done"),
      ),
    );
    _logger.i("database ready");
  }

  static Future<void> reset() async {
    _logger.i("deleting database");
    await deleteDatabase(Config.databaseName);
    _database = null;
    _logger.i("database deleted");
    await open();
  }

  static List<TableAccessor> get _tables => [
        DiaryTable(),
        WodTable(),
        MovementTable(),
        MetconTable(),
        MetconMovementTable(),
        MetconSessionTable(),
        RouteTable(),
        CardioSessionTable(),
        StrengthSessionTable(),
        StrengthSetTable(),
        PlatformTable(),
        PlatformCredentialTable(),
        ActionProviderTable(),
        ActionTable(),
        ActionRuleTable(),
        ActionEventTable(),
      ];
}
