
import 'dart:io';

import 'package:sport_log/config.dart';
import 'tables/all.dart';
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
      onCreate: (db, version) async {
        for (final table in allTables) {
          await table.init(db);
        }
      }
    );
  }

  final movements = MovementTable();
  final metcons = MetconTable();
  final metconMovements = MetconMovementTable();
  final metconSessions = MetconSessionTable();
  final routes = RouteTable();
  final cardioSessions = CardioSessionTable();
  final strengthSets = StrengthSetTable();
  final strengthSessions = StrengthSessionTable();
  final platforms = PlatformTable();
  final platformCredentials = PlatformCredentialTable();
  final actionProviders = ActionProviderTable();
  final actions = ActionTable();
  final actionRules = ActionRuleTable();
  final actionEvents = ActionEventTable();
  final diaries = DiaryTable();
  final wods = WodTable();


  List<Table> get allTables => [
    movements,
    metcons,
    metconMovements,
    metconSessions,
    routes,
    cardioSessions,
    strengthSets,
    strengthSessions,
    platforms,
    platformCredentials,
    actionProviders,
    actions,
    actionRules,
    actionEvents,
    diaries,
    wods,
  ];
}