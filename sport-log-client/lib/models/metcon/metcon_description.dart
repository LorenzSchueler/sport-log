import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/extensions/iterable_extension.dart';
import 'package:sport_log/models/all.dart';

part 'metcon_description.g.dart';

@JsonSerializable()
class MetconDescription extends CompoundEntity {
  MetconDescription({
    required this.metcon,
    required this.moves,
    required this.hasReference,
  });

  factory MetconDescription.fromJson(Map<String, dynamic> json) =>
      _$MetconDescriptionFromJson(
        json,
      ); // whether there is a MetconSession referencing this metcon

  MetconDescription.defaultValue()
      : metcon = Metcon.defaultValue(),
        moves = [],
        hasReference = false;

  Metcon metcon;
  List<MetconMovementDescription> moves;
  bool hasReference;

  static MetconDescription?
      _defaultMetconDescription; // default metcon description that already exists in db
  static set defaultMetconDescription(MetconDescription? metconDescription) =>
      _defaultMetconDescription = metconDescription;
  static MetconDescription? get defaultMetconDescription =>
      _defaultMetconDescription?.clone();

  @override
  Map<String, dynamic> toJson() => _$MetconDescriptionToJson(this);

  @override
  MetconDescription clone() => MetconDescription(
        metcon: metcon.clone(),
        moves: moves.map((m) => m.clone()).toList(),
        hasReference: hasReference,
      );

  @override
  bool isValidBeforeSanitation() {
    return metcon.isValidBeforeSanitation() &&
        moves.every((mm) => mm.isValidBeforeSanitation()) &&
        validate(moves.isNotEmpty, 'MetconDescription: moves empty') &&
        validate(
          moves.every((mmd) => mmd.metconMovement.metconId == metcon.id),
          'MetconDescription: metcon id mismatch',
        ) &&
        validate(
          moves.everyIndexed(
            (index, mmd) => mmd.metconMovement.movementNumber == index,
          ),
          'MetconDescription: moves indices wrong',
        );
  }

  @override
  bool isValid() {
    return isValidBeforeSanitation() &&
        metcon.isValid() &&
        moves.every((mm) => mm.isValid());
  }

  @override
  void sanitize() {
    metcon.sanitize();
    for (final move in moves) {
      if (move.movement.dimension != MovementDimension.distance) {
        move.metconMovement.distanceUnit = null;
      }
      move.sanitize();
    }
  }

  static bool areTheSame(MetconDescription m1, MetconDescription m2) =>
      m1.metcon.id == m2.metcon.id;

  String get typeLengthDescription {
    switch (metcon.metconType) {
      case MetconType.amrap:
        return "${metcon.metconType.name} ${metcon.timecap?.formatTimeShort}";
      case MetconType.emom:
        return metcon.timecap!.inSeconds / metcon.rounds! ==
                const Duration(minutes: 1).inSeconds
            ? "${metcon.metconType.name} ${metcon.timecap?.formatTimeShort}"
            : "${metcon.metconType.name} ${metcon.timecap?.formatTimeShort} (${metcon.rounds} x ${Duration(seconds: (metcon.timecap!.inSeconds / metcon.rounds!).round()).formatTimeShort})";
      case MetconType.forTime:
        final timecap = metcon.timecap == null
            ? ""
            : " (Timecap ${metcon.timecap?.formatTimeShort})";
        final rounds = metcon.rounds! > 1 ? "${metcon.rounds!} Rounds " : "";
        return "$rounds${metcon.metconType.name}$timecap";
    }
  }
}
