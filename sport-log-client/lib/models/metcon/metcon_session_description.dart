import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/models/entity_interfaces.dart';
import 'package:sport_log/models/metcon/metcon.dart';
import 'package:sport_log/models/metcon/metcon_description.dart';
import 'package:sport_log/models/metcon/metcon_session.dart';

part 'metcon_session_description.g.dart';

@JsonSerializable()
class MetconSessionDescription extends CompoundEntity {
  MetconSessionDescription({
    required this.metconSession,
    required this.metconDescription,
  });

  factory MetconSessionDescription.fromJson(Map<String, dynamic> json) =>
      _$MetconSessionDescriptionFromJson(json);

  MetconSession metconSession;
  MetconDescription metconDescription;

  static MetconSessionDescription? defaultValue() =>
      MetconDescription.defaultMetconDescription == null
          ? null
          : MetconSessionDescription(
              metconSession: MetconSession.defaultValue(
                MetconDescription.defaultMetconDescription!.metcon,
              ),
              metconDescription: MetconDescription.defaultMetconDescription!,
            );

  @override
  Map<String, dynamic> toJson() => _$MetconSessionDescriptionToJson(this);

  @override
  MetconSessionDescription clone() => MetconSessionDescription(
        metconSession: metconSession.clone(),
        metconDescription: metconDescription.clone(),
      );

  @override
  bool isValidBeforeSanitazion() {
    bool metconMetconDescriptionChecks;
    switch (metconDescription.metcon.metconType) {
      case MetconType.amrap:
        metconMetconDescriptionChecks = validate(
              metconSession.time == null,
              'MetconSessionDescription: time != null although amrap',
            ) &&
            validate(
              metconSession.rounds != null,
              'MetconSessionDescription: rounds != null although amrap',
            ) &&
            validate(
              metconSession.reps != null,
              'MetconSessionDescription: reps != null although amrap',
            );
        break;
      case MetconType.emom:
        metconMetconDescriptionChecks = validate(
              metconSession.time == null,
              'MetconSessionDescription: time != null although amrap',
            ) &&
            validate(
              metconSession.rounds == null,
              'MetconSessionDescription: rounds != null although amrap',
            ) &&
            validate(
              metconSession.reps == null,
              'MetconSessionDescription: reps != null although amrap',
            );
        break;
      case MetconType.forTime:
        metconMetconDescriptionChecks = validate(
          metconSession.time == null ||
              metconSession.rounds == null && metconSession.reps == null,
          'MetconSessionDescription: for "for time" either time or rounds and reps must be null',
        );
        break;
    }
    return metconSession.isValidBeforeSanitazion() &&
        metconDescription.isValidBeforeSanitazion() &&
        metconSession.metconId == metconDescription.metcon.id &&
        metconMetconDescriptionChecks;
  }

  @override
  bool isValid() {
    return isValidBeforeSanitazion() &&
        metconSession.isValid() &&
        metconDescription.isValid();
  }

  @override
  void sanitize() {
    metconSession.sanitize();
    metconDescription.sanitize();
  }

  String _resultDescription(bool short) {
    switch (metconDescription.metcon.metconType) {
      case MetconType.amrap:
        return "${metconSession.rounds} rounds + ${metconSession.reps} reps";
      case MetconType.emom:
        return "${metconDescription.metcon.rounds!} x ${Duration(seconds: (metconDescription.metcon.timecap!.inSeconds / metconDescription.metcon.rounds!).round()).formatTimeShort}";
      case MetconType.forTime:
        if (short) {
          return metconSession.time != null
              ? "${metconSession.time?.formatTimeShort} min"
              : "${metconSession.rounds} rounds + ${metconSession.reps} reps";
        } else {
          final timecap = metconDescription.metcon.timecap == null
              ? ""
              : "(${Duration(seconds: metconDescription.metcon.timecap!.inSeconds).formatTimeShort} min)";
          return metconSession.time != null
              ? "${metconSession.time?.formatTimeShort} min $timecap"
              : "${metconSession.rounds} rounds + ${metconSession.reps} reps (${metconDescription.metcon.rounds} rounds)";
        }
    }
  }

  String get longResultDescription {
    return _resultDescription(false);
  }

  String get shortResultDescription {
    return _resultDescription(true);
  }

  String get typeLengthDescription => metconDescription.typeLengthDescription;
}
