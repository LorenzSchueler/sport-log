// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cardio_dao.dart';

// **************************************************************************
// DaoGenerator
// **************************************************************************

mixin _$CardioDaoMixin on DatabaseAccessor<Database> {
  $CardioSessionsTable get cardioSessions => attachedDatabase.cardioSessions;
  $RoutesTable get routes => attachedDatabase.routes;
  Selectable<int> _cardioSessionWithRouteExists(int? id) {
    return customSelect(
        'SELECT 1 FROM cardio_sessions\n    WHERE deleted == FALSE AND route_id == :id',
        variables: [
          Variable<int?>(id)
        ],
        readsFrom: {
          cardioSessions,
        }).map((QueryRow row) => row.read<int>('1'));
  }
}
