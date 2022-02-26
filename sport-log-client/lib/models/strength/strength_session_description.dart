import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/helpers/extensions/iterable_extension.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/models/movement/all.dart';
import 'package:sport_log/models/strength/strength_session.dart';
import 'package:sport_log/models/strength/strength_session_stats.dart';
import 'package:sport_log/models/strength/strength_set.dart';

part 'strength_session_description.g.dart';

@JsonSerializable()
class StrengthSessionDescription extends CompoundEntity {
  StrengthSessionDescription({
    required this.session,
    required this.movement,
    required this.sets,
  });

  StrengthSession session;
  Movement movement;
  List<StrengthSet> sets;
  StrengthSessionStats get stats =>
      StrengthSessionStats.fromStrengthSets(session.datetime, sets);

  factory StrengthSessionDescription.fromJson(Map<String, dynamic> json) =>
      _$StrengthSessionDescriptionFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$StrengthSessionDescriptionToJson(this);

  @override
  bool isValid() {
    return validate(
          session.isValid(),
          'StrengthSessionDescription: strength session not valid',
        ) &&
        validate(
          sets.isNotEmpty,
          'StrengthSessionDescription: strength sets empty',
        ) &&
        validate(
          sets.every((ss) => ss.strengthSessionId == session.id),
          'StrengthSessionDescription: strengthSessionId != strengthSession.id',
        ) &&
        validate(
          sets.everyIndexed((ss, index) => ss.setNumber == index),
          'StrengthSessionDescription: strengthSets indices wrong',
        ) &&
        validate(
          sets.every((ss) => ss.isValid()),
          'StrengthSessionDescription: strengthSets not valid',
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

  void setDeleted() {
    session.deleted = true;
    for (final set in sets) {
      set.deleted = true;
    }
  }

  StrengthSessionDescription.defaultValue(this.movement, Int64 userId)
      : session = StrengthSession(
          id: randomId(),
          userId: userId,
          datetime: DateTime.now(),
          movementId: movement.id,
          interval: null,
          comments: null,
          deleted: false,
        ),
        sets = [];

  StrengthSessionDescription copy() {
    return StrengthSessionDescription(
      session: session.copy(),
      movement: movement.copy(),
      sets: sets.mapToList((set) => set.copy()),
    );
  }
}
