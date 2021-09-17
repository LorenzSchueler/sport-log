import 'package:result_type/result_type.dart';
import 'package:sport_log/helpers/interfaces.dart';

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

abstract class DbObject implements Validatable, HasId {
  bool get deleted;
  set deleted(bool deleted);
}

abstract class DbObjectWithDateTime implements DbObject, HasDateTime {}

abstract class DbSerializer<T> {
  DbRecord toDbRecord(T o);
  T fromDbRecord(DbRecord r);
}

typedef DbResult<T> = Future<Result<T, DbError>>;
