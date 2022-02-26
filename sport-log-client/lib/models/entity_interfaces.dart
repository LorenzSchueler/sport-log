import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';

abstract class HasId {
  Int64 get id;
}

abstract class Validatable {
  bool isValid();
}

abstract class Entity extends JsonSerializable implements Validatable {
  @override
  String toString() => toJson().toString();
}

abstract class CompoundEntity extends Entity {}

abstract class NonDeletableAtomicEntity extends Entity implements HasId {}

abstract class AtomicEntity extends NonDeletableAtomicEntity {
  bool get deleted;

  set deleted(bool deleted);
}
