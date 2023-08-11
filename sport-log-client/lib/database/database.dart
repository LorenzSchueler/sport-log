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
          _logger.i("upgrading db from version $oldVersion to $newVersion");
          if (oldVersion < 2 && newVersion >= 2) {
            await db.transaction((txn) async {
              await txn.execute("pragma defer_foreign_keys = on;");

              // drop indices
              await txn.execute(
                "drop index ${Tables.cardioSession}__movement_id__datetime__key;",
              );
              await txn.execute(
                "drop index ${Tables.metconSession}__metcon_id__datetime__key;",
              );
              await txn.execute(
                "drop index ${Tables.strengthSession}__datetime__movement_id__key;",
              );

              // create isDefaultMovement / isDefaultMetcon columns based on userId
              final optionalUserIdTables = [
                (Tables.movement, Columns.isDefaultMovement),
                (Tables.metcon, Columns.isDefaultMetcon),
              ];
              for (final (table, column) in optionalUserIdTables) {
                await txn.execute(
                  "alter table $table add column $column integer not null default 0 check($column in (0, 1));",
                );
                await txn.execute(
                  "update $table set $column = user_id is null;",
                );
              }

              final dropColumnTables = <TableAccessor>[
                DiaryTable(), // drop user_id
                WodTable(), // drop user_id
                MovementTable(), // drop user_id
                MetconTable(), // drop user_id
                MetconSessionTable(), // drop user_id
                RouteTable(), // drop user_id, drop not null on distance
                CardioSessionTable(), // drop user_id, drop not null on distance
                StrengthSessionTable(), // drop user_id
                PlatformCredentialTable(), // drop user_id
                ActionProviderTable(), // drop password
                ActionTable(), // drop create_before and delete_after
                ActionRuleTable(), // drop user_id
                ActionEventTable(), // drop user_id
              ];
              for (final tableAccessor in dropColumnTables) {
                // "alter table drop column" only supported beginning with sqlite 3.35.0
                // "alter table alter column drop not null" not supported
                // therefore create new table and copy all relevant data over
                final table = tableAccessor.table.name;
                final newTable = "new_$table";

                // create new table
                final tableSetupSql =
                    tableAccessor.table.withName(newTable).tableSetupSql;
                _logger.i(tableSetupSql);
                await txn.execute(tableSetupSql);

                // insert all columns of new table from old table into new table
                final columnNameList =
                    tableAccessor.table.columns.map((c) => c.name).join(', ');
                await txn.execute(
                  "insert into $newTable ($columnNameList) select $columnNameList from $table;",
                );

                // drop old table
                _logger.i("drop table $table;");
                await txn.execute("drop table $table;");

                // rename new table to original name
                _logger.i("alter table $newTable rename to $table;");
                await txn.execute("alter table $newTable rename to $table;");

                // create indices, triggers and rawSql for new renamed tabled
                final setupSql = [
                  ...tableAccessor.table.uniqueIndicesSetupSql,
                  tableAccessor.table.triggerSetupSql,
                  ...tableAccessor.table.rawSql,
                ];
                for (final statement in setupSql) {
                  _logger.i(statement);
                  await txn.execute(statement);
                }
              }
              await txn.execute("pragma defer_foreign_keys = off;");
            });
            _logger.i("migration to version 2 done");
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
