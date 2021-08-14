// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'strength_dao.dart';

// **************************************************************************
// DaoGenerator
// **************************************************************************

mixin _$StrengthDaoMixin on DatabaseAccessor<Database> {
  $StrengthSessionsTable get strengthSessions =>
      attachedDatabase.strengthSessions;
  $StrengthSetsTable get strengthSets => attachedDatabase.strengthSets;
  Selectable<Int64> _strengthSetIdsOfSession(int id) {
    return customSelect(
        'SELECT id FROM strength_sets\n    WHERE strength_session_id == :id AND deleted == false',
        variables: [
          Variable<int>(id)
        ],
        readsFrom: {
          strengthSets,
        }).map((QueryRow row) =>
        $StrengthSetsTable.$converter0.mapToDart(row.read<int>('id'))!);
  }
}
