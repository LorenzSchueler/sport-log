
import 'dart:io';

import 'package:moor/ffi.dart';
import 'package:moor/moor.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/database/metcon/metcon_tables.dart';
import 'package:sport_log/database/metcon/metcons_deletion_dao.dart';

part 'database.g.dart';

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(join(dbFolder.path, 'db.sqlite'));
    return VmDatabase(file);
  });
}

@UseMoor(
  tables: [Metcons, MetconMovements, MetconSessions],
  daos: [MetconsDeletionDao]
)
class Database extends _$Database {

  static Database? instance = Config.isWeb ? null : Database._();

  Database._() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}