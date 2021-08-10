

import 'package:fixnum/fixnum.dart';
import 'package:moor/moor.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/helpers/id_serialization.dart';
import 'package:sport_log/models/metcon/metcon_movement.dart';
import 'package:sport_log/models/movement/movement.dart';

export 'package:sport_log/models/metcon/metcon_movement.dart';
export 'package:sport_log/models/movement/movement.dart';

part 'metcon_movements.g.dart';

@UseRowClass(MetconMovement)
class MetconMovements extends Table {
  IntColumn get id => integer().map(const DbIdConverter())();
  IntColumn get metconId => integer().map(const DbIdConverter())();
  IntColumn get movementId => integer().map(const DbIdConverter())();
  IntColumn get movementNumber => integer()();
  IntColumn get count => integer()();
  IntColumn get unit => intEnum<MovementUnit>()();
  RealColumn get weight => real().nullable()();

  BoolColumn get deleted => boolean().withDefault(const Constant(true))();
  DateTimeColumn get lastModified => dateTime().clientDefault(() => DateTime.now())();
  BoolColumn get isNew => boolean().withDefault(const Constant(true))();

  @override
  Set<Column>? get primaryKey => {id};
}

@UseDao(tables: [MetconMovements])
class MetconMovementsDao extends DatabaseAccessor<Database> with _$MetconMovementsDaoMixin {
  MetconMovementsDao(Database attachedDatabase) : super(attachedDatabase);


  Future<void> insertMetconMovement(MetconMovement metconMovement) async {
    assert(metconMovement.deleted == false);
    into(metconMovements).insert(metconMovement);
  }

  Future<List<MetconMovement>> getAllMetcons() async {
    return (select(metconMovements)
      ..where((mm) => mm.deleted.equals(false))
    ).get();
  }

  Future<void> updateMetconMovement(MetconMovement metconMovement) async {
    assert(metconMovement.deleted == false);
    (update(metconMovements)
      ..where((mm) => mm.id.equals(metconMovement.id.toInt()))
    ).write(metconMovement);
  }

  Future<void> setAllIsNewFalse() async {
    (update(metconMovements)
      ..where((mm) => mm.isNew.equals(true))
    ).write(const MetconMovementsCompanion(isNew: Value(false)));
  }

  Future<void> deleteMetconMovement(Int64 id) async {
    (update(metconMovements)
      ..where((mm) => mm.id.equals(id.toInt()))
    ).write(const MetconMovementsCompanion(deleted: Value(true)));
  }
}