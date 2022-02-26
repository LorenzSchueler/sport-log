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

abstract class DbSerializer<T> {
  DbRecord toDbRecord(T o);

  T fromDbRecord(DbRecord r, {String prefix = ''});

  T? fromOptionalDbRecord(DbRecord r, {String prefix = ''}) {
    return r[prefix + Columns.id] == null
        ? null
        : fromDbRecord(r, prefix: prefix);
  }
}
