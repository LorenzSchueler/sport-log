import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/defs.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/keys.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';

part 'metcon.g.dart';

enum MetconType {
  @JsonValue("Amrap")
  amrap,
  @JsonValue("Emom")
  emom,
  @JsonValue("ForTime")
  forTime
}

extension ToDisplayName on MetconType {
  String toDisplayName() {
    switch (this) {
      case MetconType.amrap:
        return "AMRAP";
      case MetconType.emom:
        return "EMOM";
      case MetconType.forTime:
        return "FOR TIME";
    }
  }
}

@JsonSerializable()
class Metcon implements DbObject {
  Metcon({
    required this.id,
    required this.userId,
    required this.name,
    required this.metconType,
    required this.rounds,
    required this.timecap,
    required this.description,
    required this.deleted,
  });

  @override
  @IdConverter()
  Int64 id;
  @OptionalIdConverter()
  Int64? userId;
  String? name;

  // TODO: rename type
  MetconType metconType;
  int? rounds;
  @DurationConverter()
  Duration? timecap;
  String? description;
  @override
  bool deleted;

  static const Duration timecapDefaultValue = Duration(minutes: 30);
  static const int roundsDefaultValue = 3;

  Metcon.defaultValue(this.userId)
      : id = randomId(),
        name = "",
        metconType = MetconType.amrap,
        rounds = null,
        timecap = timecapDefaultValue,
        description = null,
        deleted = false;

  factory Metcon.fromJson(Map<String, dynamic> json) => _$MetconFromJson(json);

  Map<String, dynamic> toJson() => _$MetconToJson(this);

  bool validateMetconType() {
    switch (metconType) {
      case MetconType.amrap:
        return validate(rounds == null, 'Metcon: amrap: rounds != null') &&
            validate(timecap != null, 'Metcon: amrap: timecap == null');
      case MetconType.emom:
        return validate(rounds != null, 'Metcon: emom: rounds == null') &&
            validate(timecap != null, 'Metcon: emom: timecap == null');
      case MetconType.forTime:
        return validate(rounds != null, 'Metcon: forTime: rounds == null');
    }
  }

  @override
  bool isValid() {
    return validate(userId != null, 'Metcon: userId == null') &&
        validate(name != null, 'Metcon: name == null') &&
        validate(name!.isNotEmpty, 'Metcon: name is empty') &&
        validate(deleted != true, 'Metcon: deleted == true') &&
        validate(rounds == null || rounds! >= 1, 'Metcon: rounds < 1') &&
        validate(timecap == null || timecap! >= const Duration(seconds: 1),
            'Metcon: timecap < 1s') &&
        validate(validateMetconType(), 'Metcon: metcon type validation failed');
  }
}

class DbMetconSerializer implements DbSerializer<Metcon> {
  @override
  Metcon fromDbRecord(DbRecord r) {
    return Metcon(
      id: Int64(r[Keys.id]! as int),
      userId: r[Keys.userId] == null ? null : Int64(r[Keys.userId]! as int),
      name: r[Keys.name] as String?,
      metconType: MetconType.values[r[Keys.metconType]! as int],
      rounds: r[Keys.rounds] as int?,
      timecap: r[Keys.timecap] == null
          ? null
          : Duration(seconds: r[Keys.timecap]! as int),
      description: r[Keys.description] as String?,
      deleted: r[Keys.deleted]! as int == 1,
    );
  }

  @override
  DbRecord toDbRecord(Metcon o) {
    return {
      Keys.id: o.id.toInt(),
      Keys.userId: o.userId?.toInt(),
      Keys.name: o.name,
      Keys.metconType: o.metconType.index,
      Keys.rounds: o.rounds,
      Keys.timecap: o.timecap?.inSeconds,
      Keys.description: o.description,
      Keys.deleted: o.deleted ? 1 : 0,
    };
  }
}
