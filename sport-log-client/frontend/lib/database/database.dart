
import 'package:sport_log/config.dart';
import 'package:sport_log/database/metcon/metcon_table.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {

  static final AppDatabase? _instance = Config.isAndroid || Config.isIOS
      ? AppDatabase._() : null;

  static AppDatabase? get instance => _instance;

  AppDatabase._();

  late Database _db;

  Future<void> init() async {
    final _db = await openDatabase('database.sqlite');

    metcons = MetconTable(_db);
  }

  late MetconTable metcons;
}