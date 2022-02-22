import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/table.dart';

export 'package:sport_log/helpers/validation.dart';

typedef DbRecord = Map<String, Object?>;

enum DbError {
  unknown,
  validationFailed,
}

enum SyncStatus {
  synchronized,
  updated,
  created,
}

abstract class Entity extends JsonSerializable implements Validatable, HasId {
  bool get deleted;

  set deleted(bool deleted);
}

abstract class DbSerializer<T> {
  DbRecord toDbRecord(T o);

  T fromDbRecord(DbRecord r, {String prefix = ''});

  T? fromDbRecordNullable(DbRecord r, {String prefix = ''}) {
    return r[prefix + Columns.id] == null
        ? null
        : fromDbRecord(r, prefix: prefix);
  }
}

abstract class HasId {
  Int64 get id;
}

abstract class Validatable {
  bool isValid();
}
