import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/helpers/extensions/iterable_extension.dart';
import 'package:sport_log/models/entity_interfaces.dart';
import 'package:sport_log/models/metcon/all.dart';

part 'metcon_description.g.dart';

@JsonSerializable()
class MetconDescription extends CompoundEntity {
  MetconDescription({
    required this.metcon,
    required this.moves,
    required this.hasReference,
  });

  Metcon metcon;
  List<MetconMovementDescription> moves;
  bool hasReference; // whether there is a MetconSession referencing this metcon

  String get name {
    return metcon.name ?? moves.map((e) => e.movement.name).join(" & ");
  }

  MetconDescription.defaultValue()
      : metcon = Metcon.defaultValue(),
        moves = [],
        hasReference = false;

  static late MetconDescription
      defaultMetconDescription; // must be initialized in main::initialize

  factory MetconDescription.fromJson(Map<String, dynamic> json) =>
      _$MetconDescriptionFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$MetconDescriptionToJson(this);

  @override
  bool isValid() {
    return validate(metcon.isValid(), 'MetconDescription: metcon not valid') &&
        validate(moves.isNotEmpty, 'MetconDescription: moves empty') &&
        validate(
          moves.every((mmd) => mmd.metconMovement.metconId == metcon.id),
          'MetconDescription: metcon id mismatch',
        ) &&
        validate(
          moves.everyIndexed(
            (mmd, index) => mmd.metconMovement.movementNumber == index,
          ),
          'MetconDescription: moves indices wrong',
        ) &&
        validate(
          moves.every((mm) => mm.isValid()),
          'MetconDescription: moves not valid',
        );
  }

  static bool areTheSame(MetconDescription m1, MetconDescription m2) =>
      m1.metcon.id == m2.metcon.id;

  void setDeleted() {
    metcon.deleted = true;
    for (final move in moves) {
      move.metconMovement.deleted = true;
    }
  }
}
