// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metcons_deletion_dao.dart';

// **************************************************************************
// DaoGenerator
// **************************************************************************

mixin _$MetconsDeletionDaoMixin on DatabaseAccessor<Database> {
  $MetconsTable get metcons => attachedDatabase.metcons;
  $MetconMovementsTable get metconMovements => attachedDatabase.metconMovements;
  $MetconSessionsTable get metconSessions => attachedDatabase.metconSessions;
  Selectable<int> metconHasMetconSession(int id) {
    return customSelect(
        'SELECT 1 FROM metcon_sessions\n    WHERE metcon_id == :id AND deleted == false',
        variables: [
          Variable<int>(id)
        ],
        readsFrom: {
          metconSessions,
        }).map((QueryRow row) => row.read<int>('1'));
  }
}
