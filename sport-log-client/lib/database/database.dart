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
import 'package:sport_log/helpers/result.dart';
import 'package:sqflite/sqflite.dart';

final _logger = Logger('DB');

enum DbErrorCode { uniqueViolation, unknown }

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
      } on RangeError {
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
      DbErrorCode.unknown =>
        databaseException != null
            ? "Unknown database error: $databaseException"
            : "Unknown database error",
    };
  }
}

typedef DbResult = Result<void, DbError>;

extension DbResultExt on Result<void, DbError> {
  static DbResult fromBool(bool condition) =>
      condition ? Ok(null) : Err(DbError.unknown(null));

  static Future<DbResult> catchError(Future<DbResult> Function() fn) async {
    try {
      return await fn();
    } on DatabaseException catch (e) {
      return Err(DbError.fromDbException(e));
    }
  }
}

abstract final class AppDatabase {
  static Database? _database;

  /// This should only be called after the database was initialized.
  static Database get database => _database!;

  static Future<void> init() async {
    if (Config.instance.deleteDatabase) {
      await reset();
    } else {
      await open();
    }
  }

  static Future<void> _execute(DatabaseExecutor db, String statement) async {
    if (Config.instance.outputDbStatement) {
      _logger.t(statement);
    }
    await db.execute(statement);
  }

  // ignore: long-method
  static Future<void> open() async {
    _logger.i("opening database");
    _database = await databaseFactory.openDatabase(
      Config.databaseName,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, version) async {
          for (final table in _tables) {
            _logger.i("creating table: ${table.tableName}");
            for (final statement in table.table.setupSql) {
              await _execute(db, statement);
            }
          }
          for (final statement in eormTable.setupSql) {
            await _execute(db, statement);
          }
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          // onUpgrade is executed in a single transaction
          // foreign keys are not yet enabled
          _logger.i("upgrading db from version $oldVersion to $newVersion");
          if (oldVersion < 2 && newVersion >= 2) {
            // drop indices
            await _execute(
              db,
              "drop index ${Tables.cardioSession}__movement_id__datetime__key;",
            );
            await _execute(
              db,
              "drop index ${Tables.metconSession}__metcon_id__datetime__key;",
            );
            await _execute(
              db,
              "drop index ${Tables.strengthSession}__datetime__movement_id__key;",
            );

            // create isDefaultMovement / isDefaultMetcon columns based on userId
            final optionalUserIdTables = [
              (Tables.movement, Columns.isDefaultMovement),
              (Tables.metcon, Columns.isDefaultMetcon),
            ];
            for (final (table, column) in optionalUserIdTables) {
              await _execute(
                db,
                "alter table $table add column $column integer not null default 0 check($column in (0, 1));",
              );
              await _execute(
                db,
                "update $table set $column = user_id is null;",
              );
              // set default movements/ metcons as synchronized as they can not be updated by the user
              // all user defined movements/ metcons stay in the updated state in case they were there before
              await _execute(
                db,
                "update $table set ${Columns.syncStatus} = ${SyncStatus.synchronized.index} where $column = true;",
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
              // see: https://www.sqlite.org/lang_altertable.html
              // "alter table drop column" only supported beginning with sqlite 3.35.0
              // "alter table alter column drop not null" not supported
              // therefore create new table and copy all relevant data over
              final table = tableAccessor.table.name;
              final newTable = "new_$table";

              // create new table
              final tableSetupSql = tableAccessor.table
                  .withName(newTable)
                  .tableSetupSql;
              await _execute(db, tableSetupSql);

              // insert all columns of new table from old table into new table
              final columns = tableAccessor.table.columns
                  .map((c) => c.name)
                  .join(', ');
              await _execute(
                db,
                "insert into $newTable ($columns) select $columns from $table;",
              );

              // drop old table
              await _execute(db, "drop table $table;");

              // rename new table to original name
              await _execute(db, "alter table $newTable rename to $table;");

              // create indices, triggers and rawSql for new renamed tabled
              final setupSql = [
                ...tableAccessor.table.uniqueIndicesSetupSql,
                tableAccessor.table.triggerSetupSql,
                ...tableAccessor.table.rawSql,
              ];
              for (final statement in setupSql) {
                await _execute(db, statement);
              }
            }
            _logger.i("migration to version 2 done");
          }
          _logger.i("database migration done");
        },
        //onDowngrade: null,
        onOpen: (db) async {
          await _execute(db, "pragma foreign_keys = on;");
          _logger.i("database initialization done");
        },
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
