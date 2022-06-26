import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/helpers/extensions/iterable_extension.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/models/entity_interfaces.dart';
import 'package:sport_log/models/movement/all.dart';
import 'package:sport_log/models/strength/strength_session.dart';
import 'package:sport_log/models/strength/strength_session_stats.dart';
import 'package:sport_log/models/strength/strength_set.dart';
import 'package:sport_log/settings.dart';

part 'strength_session_description.g.dart';

@JsonSerializable()
class StrengthSessionDescription extends CompoundEntity {
  StrengthSessionDescription({
    required this.session,
    required this.movement,
    required this.sets,
  });

  factory StrengthSessionDescription.fromJson(Map<String, dynamic> json) =>
      _$StrengthSessionDescriptionFromJson(json);

  StrengthSession session;
  Movement movement;
  List<StrengthSet> sets;

  StrengthSessionStats get stats => StrengthSessionStats.fromStrengthSets(
        session.datetime,
        movement.dimension,
        sets,
      );

  static StrengthSessionDescription? defaultValue() =>
      Movement.defaultMovement == null
          ? null
          : StrengthSessionDescription(
              session: StrengthSession(
                id: randomId(),
                userId: Settings.instance.userId!,
                datetime: DateTime.now(),
                movementId: Movement.defaultMovement!.id,
                interval: null,
                comments: null,
                deleted: false,
              ),
              movement: Movement.defaultMovement!,
              sets: [],
            );

  @override
  Map<String, dynamic> toJson() => _$StrengthSessionDescriptionToJson(this);

  @override
  StrengthSessionDescription clone() => StrengthSessionDescription(
        session: session.clone(),
        movement: movement.clone(),
        sets: sets.map((s) => s.clone()).toList(),
      );

  @override
  bool isValidBeforeSanitazion() {
    return session.isValidBeforeSanitazion() &&
        movement.isValid() &&
        sets.every((ss) => ss.isValidBeforeSanitazion()) &&
        validate(
          sets.isNotEmpty,
          'StrengthSessionDescription: strength sets empty',
        ) &&
        validate(
          sets.every((ss) => ss.strengthSessionId == session.id),
          'StrengthSessionDescription: strengthSessionId != strengthSession.id',
        ) &&
        validate(
          sets.everyIndexed((index, ss) => ss.setNumber == index),
          'StrengthSessionDescription: strengthSets indices wrong',
        ) &&
        validate(
          session.movementId == movement.id,
          'StrengthSessionDescription: movement id mismatch',
        ) &&
        validate(
          !movement.deleted,
          'StrengthSessionDescription: movement is deleted',
        );
  }

  @override
  bool isValid() {
    return isValidBeforeSanitazion() &&
        session.isValid() &&
        sets.every((ss) => ss.isValid());
  }

  @override
  void sanitize() {
    session.sanitize();
    for (final StrengthSet set in sets) {
      set.sanitize();
    }
  }

  void orderSets() {
    sets.forEachIndexed((index, set) => set.setNumber = index);
  }
}
