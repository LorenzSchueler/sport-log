
import 'package:fixnum/fixnum.dart';
import 'package:result_type/result_type.dart';
import 'package:sport_log/helpers/update_validatable.dart';

typedef DbRecord = Map<String, Object?>;

enum DbError {
  unknown,
  validationFailed,
}

abstract class DbObject extends Validatable {
  Int64 get id;
  bool get deleted;
}

abstract class DbSerializer<T> {
  DbRecord toDbRecord(T object);
  T fromDbRecord(DbRecord record);
}

typedef DbResult<T> = Future<Result<T, DbError>>;