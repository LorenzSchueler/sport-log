
import 'package:sport_log/database/defs.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/models/all.dart';
import 'package:sqflite_common/sqlite_api.dart';

class MetconTable extends Table<Metcon> {
  MetconTable(Database database) : super(database);

  @override
  // TODO: implement createTable
  String get createTable => throw UnimplementedError();

  @override
  // TODO: implement serde
  DbSerializer<Metcon> get serde => throw UnimplementedError();

  @override
  // TODO: implement tableName
  String get tableName => throw UnimplementedError();
}