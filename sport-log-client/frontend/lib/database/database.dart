
import 'dart:io';

import 'package:sport_log/config.dart';
import 'package:sport_log/database/metcon/metcon.dart';
import 'package:sport_log/database/metcon/metcon_movement.dart';
import 'package:sport_log/database/metcon/metcon_session.dart';
import 'package:sport_log/database/movement/movement.dart';
import 'package:sport_log/database/table.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {

  static final AppDatabase? _instance = Config.isAndroid || Config.isIOS
      ? AppDatabase._() : null;

  static AppDatabase? get instance => _instance;

  AppDatabase._();

  late Database _db;

  Future<void> init() async {
    const fileName = 'database.sqlite';
    final File databaseFile = File(await getDatabasesPath() + '/' + fileName);
    // TODO: remove this
    if (await databaseFile.exists()) {
      await databaseFile.delete();
    }
    _db = await openDatabase(
      fileName,
      version: 1,
      onConfigure: (db) => db.execute("PRAGMA foreign_keys = ON;"),
      onCreate: (db, version) {
        for (final table in allTables) {
          table.init(db);
        }
      }
    );
  }

  final movements = MovementTable();
  final metcons = MetconTable();
  final metconMovements = MetconMovementTable();
  final metconSessions = MetconSessionTable();

  List<Table> get allTables => [
    movements,
    metcons,
    metconMovements,
    metconSessions,
  ];
}