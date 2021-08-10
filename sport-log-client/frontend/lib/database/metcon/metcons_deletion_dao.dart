
import 'package:fixnum/fixnum.dart';
import 'package:flutter/services.dart';
import 'package:moor/moor.dart';
import 'package:sport_log/database/database.dart';
import 'metcon_tables.dart';

part 'metcons_deletion_dao.g.dart';

enum DbException {
  metconHasMetconSession,
}

@UseDao(
  tables: [Metcons, MetconSessions, MetconMovements],
  include: {'metcons.moor'}
)
class MetconsDeletionDao extends DatabaseAccessor<Database> with _$MetconsDeletionDaoMixin {
  MetconsDeletionDao(Database attachedDatabase) : super(attachedDatabase);

  Future<void> deleteMetcon(Int64 id) async {
    if (await metconHasMetconSession(id.toInt()).getSingleOrNull() != null) {
      // there is still a metcon session left
      throw DbException.metconHasMetconSession;
    }
    return transaction(() async {
      await deleteMetconMovementsOfMetcon(id);
      await unsafeDeleteMetcon(id);
    });
  }

  Future<void> deleteMetconMovementsOfMetcon(Int64 id) async {
    (update(metconMovements)
      ..where((mm) => mm.metconId.equals(id.toInt()) & mm.deleted.equals(false))
    ).write(const MetconMovementsCompanion(deleted: Value(true)));
  }

  Future<void> unsafeDeleteMetcon(Int64 id) async {
    (update(metcons)
      ..where((m) => m.id.equals(id.toInt()) & m.deleted.equals(false))
    ).write(const MetconsCompanion(deleted: Value(true)));
  }

  Future<void> deleteMetconSession(Int64 id) async {
    (update(metconSessions)
      ..where((ms) => ms.id.equals(id.toInt()) & ms.deleted.equals(false))
    ).write(const MetconSessionsCompanion(deleted: Value(true)));
  }
}
