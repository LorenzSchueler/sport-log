import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';

abstract class HasId {
  Int64 get id;
}

abstract class Entity extends JsonSerializable {
  @override
  String toString() => toJson().toString();

  Entity clone();

  /// Check if entity is valid. If true no check constraints should fail.
  bool isValid();

  /// Check if entity would be valid after [sanitize] is applied.
  bool isValidBeforeSanitation();

  /// set empty lists to null, set fields <= 0 to null if they are (check > 0), ...
  void sanitize();
}

abstract class CompoundEntity extends Entity {}

abstract class NonDeletableAtomicEntity extends Entity implements HasId {}

abstract class AtomicEntity extends NonDeletableAtomicEntity {
  bool get deleted;

  set deleted(bool deleted);
}
