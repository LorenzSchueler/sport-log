// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metcons_dao.dart';

// **************************************************************************
// DaoGenerator
// **************************************************************************

mixin _$MetconsDaoMixin on DatabaseAccessor<Database> {
  $MetconsTable get metcons => attachedDatabase.metcons;
  $MetconMovementsTable get metconMovements => attachedDatabase.metconMovements;
  $MetconSessionsTable get metconSessions => attachedDatabase.metconSessions;
  Selectable<int> _metconExists(int id) {
    return customSelect(
        'SELECT 1 FROM metcons\n    WHERE id == :id AND deleted == false',
        variables: [
          Variable<int>(id)
        ],
        readsFrom: {
          metcons,
        }).map((QueryRow row) => row.read<int>('1'));
  }

  Selectable<Int64> _idsOfMetconMovementsOfMetcon(int id) {
    return customSelect(
        'SELECT id from metcon_movements\n    WHERE metcon_id == :id AND deleted == false',
        variables: [
          Variable<int>(id)
        ],
        readsFrom: {
          metconMovements,
        }).map((QueryRow row) =>
        $MetconMovementsTable.$converter0.mapToDart(row.read<int>('id'))!);
  }

  Selectable<int> _metconMovementWithMovementExists(int id) {
    return customSelect(
        'SELECT 1 FROM metcon_movements\n    WHERE movement_id == :id AND deleted == false',
        variables: [
          Variable<int>(id)
        ],
        readsFrom: {
          metconMovements,
        }).map((QueryRow row) => row.read<int>('1'));
  }
}
