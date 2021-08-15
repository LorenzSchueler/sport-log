
import 'dart:developer';
import 'dart:io';

import 'package:moor/ffi.dart';
import 'package:moor/moor.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/database/metcons/metcon_tables.dart';
import 'package:fixnum/fixnum.dart';
import 'package:sport_log/database/movements/movement_table.dart';
import 'package:sport_log/database/movements/movements_dao.dart';
import 'package:sport_log/database/strength/strength_dao.dart';
import 'package:sport_log/database/strength/strength_tables.dart';
import 'package:sport_log/models/metcon/all.dart';
import 'package:sport_log/models/movement/all.dart';

import 'metcons/metcons_dao.dart';
// TODO: fix imports

part 'database.g.dart';

enum DbException {
  metconHasMetconSession,
  metconDoesNotExist,
  validationFailed,
  movementHasDependency,
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(join(dbFolder.path, Config.databaseName));
    if (file.existsSync()) {
      log("Deleting existing database...", name: "db");
      file.deleteSync();
    }
    return VmDatabase(file);
  });
}

@UseMoor(
  tables: [
    Metcons,
    MetconMovements,
    MetconSessions,
    Movements,
    StrengthSessions,
    StrengthSets,
  ],
  daos: [
    MetconsDao,
    MovementsDao,
    StrengthDao,
  ],
)
class Database extends _$Database {

  static Database? instance = Config.isWeb ? null : Database._();

  Database._() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON;');
    },
  );
}