// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'movements_dao.dart';

// **************************************************************************
// DaoGenerator
// **************************************************************************

mixin _$MovementsDaoMixin on DatabaseAccessor<Database> {
  $MovementsTable get movements => attachedDatabase.movements;
  Selectable<int> _movementExists(int id) {
    return customSelect(
        'SELECT 1 FROM movements\n    WHERE id == :id AND deleted == false',
        variables: [
          Variable<int>(id)
        ],
        readsFrom: {
          movements,
        }).map((QueryRow row) => row.read<int>('1'));
  }
}
