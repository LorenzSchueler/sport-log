
import 'dart:developer';
import 'dart:io';

import 'package:moor/ffi.dart';
import 'package:moor/moor.dart';
import 'package:fixnum/fixnum.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/helpers/db_serialization.dart';
import 'all_subfolders.dart';
import 'package:sport_log/models/all.dart';

part 'database.g.dart';

enum DbException {
  doesNotExist,
  validationFailed,
  hasDependency,
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
    CardioSessions,
    Routes,
    Wods,
    Diaries,
  ],
  daos: [
    MetconsDao,
    MovementsDao,
    StrengthDao,
    CardioDao,
    WodDao,
    DiaryDao,
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