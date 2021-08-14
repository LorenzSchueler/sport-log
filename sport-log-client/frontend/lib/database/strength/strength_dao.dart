
import 'package:fixnum/fixnum.dart';
import 'package:moor/moor.dart';
import 'package:result_type/result_type.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/strength/strength_tables.dart';
import 'package:sport_log/models/strength/all.dart';

part 'strength_dao.g.dart';

@UseDao(
  tables: [StrengthSets, StrengthSessions],
  include: {'strength.moor'},
)
class StrengthDao extends DatabaseAccessor<Database> with _$StrengthDaoMixin {
  StrengthDao(Database attachedDatabase) : super(attachedDatabase);

  Future<Result<void, DbException>> createStrengthSession(
      StrengthSessionDescription strengthSessionDescription) async {
    if (!strengthSessionDescription.validateOnUpdate()) {
      return Failure(DbException.validationFailed);
    }
    return transaction(() async {
      await (into(strengthSessions).insert(
        strengthSessionDescription.strengthSession
      ));
      await batch((batch) {
        batch.insertAll(strengthSets, strengthSessionDescription.strengthSets);
      });

      return Success(null);
    });
  }

  Future<void> deleteStrengthSession(Int64 id) async {
    return transaction(() async {
      await _deleteStrengthSetsOfStrengthSession(id);
      await _unsafeDeleteStrengthSession(id);
    });
  }

  Future<void> _unsafeDeleteStrengthSession(Int64 id) async {
    await (update(strengthSessions)
      ..where((ss) => ss.id.equals(id.toInt()) & ss.deleted.equals(false))
    ).write(const StrengthSessionsCompanion(deleted: Value(true)));
  }

  Future<void> _deleteStrengthSetsOfStrengthSession(Int64 id) async {
    await (update(strengthSets)
      ..where((ss) => ss.strengthSessionId.equals(id.toInt())
      & ss.deleted.equals(false)))
        .write(const StrengthSessionsCompanion(deleted: Value(true)));
  }

  Future<List<StrengthSessionDescription>> getAllStrengthSessions() async {
    final sessions = await (select(strengthSessions)
      ..where((ss) => ss.deleted.equals(false))
    ).get();

    return Future.wait(sessions.map((s) async {
      return StrengthSessionDescription(
          strengthSession: s,
          strengthSets: await _getStrengthSetsOfSession(s.id),
      );
    }));
  }

  // FIXME: type?
  Future _getStrengthSetsOfSession(Int64 id) async {
    return (select(strengthSets)
      ..where((ss) => ss.strengthSessionId.equals(id.toInt())
      & ss.deleted.equals(false))
    ).get();
  }

  Future<Result<void, DbException>> updateStrengthSession(
      StrengthSessionDescription strengthSessionDescription) async {
    if (!strengthSessionDescription.validateOnUpdate()) {
      return Failure(DbException.validationFailed);
    }

    final StrengthSession session = strengthSessionDescription.strengthSession;
    final List<StrengthSet> sets = strengthSessionDescription.strengthSets;

    // TODO: validate that session really exists
    return transaction(() async {
      await (update(strengthSessions)
        ..where((ss) => ss.id.equals(session.id.toInt())
        & ss.deleted.equals(false))
      ).write(session);

      final oldSetIds = (await _strengthSetIdsOfSession(session.id.toInt())
        .get())
        .map((id) => id.toInt())
        .toSet();
      List<StrengthSet> toCreate = [];
      List<StrengthSet> toUpdate = [];

      for (final s in sets) {
        if (!oldSetIds.contains(s.id.toInt())) {
          toCreate.add(s);
        } else {
          toUpdate.add(s);
        }

        Set<int> toDelete = oldSetIds.difference(
          toUpdate.map((s) => s.id.toInt()).toSet());

        await batch((batch) async {
          for (int id in toDelete) {
            batch.update(
                strengthSets,
                const StrengthSetsCompanion(deleted: Value(true)),
                where: ($StrengthSetsTable s) =>
                  s.id.equals(id) & s.deleted.not()
            );
          }
          for (final set in toUpdate) {
            batch.update(
              strengthSets,
              set,
              where: ($StrengthSetsTable s) =>
                s.id.equals(set.id.toInt()) & s.deleted.not()
            );
          }
          batch.insertAll(strengthSets, toCreate);
        });
      }

      return Success(null);
    });
  }
}