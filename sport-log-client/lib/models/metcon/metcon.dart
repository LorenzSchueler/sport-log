
import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/defs.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';

part 'metcon.g.dart';

enum MetconType {
  @JsonValue("Amrap") amrap,
  @JsonValue("Emom") emom,
  @JsonValue("ForTime") forTime
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
  @IdConverter() Int64 id;
  @OptionalIdConverter() Int64? userId;
  String? name;
  MetconType metconType;
  int? rounds;
  int? timecap;
  String? description;
  @override
  bool deleted;

  factory Metcon.fromJson(Map<String, dynamic> json) => _$MetconFromJson(json);
  Map<String, dynamic> toJson() => _$MetconToJson(this);

  bool validateMetconType() {
    switch (metconType) {
      case MetconType.amrap:
        return rounds == null && timecap != null;
      case MetconType.emom:
        return rounds != null && timecap != null;
      case MetconType.forTime:
        return rounds != null;
    }
  }

  @override
  bool isValid() {
    return userId != null
        && name != null
        && deleted != true
        && (rounds == null || rounds! >= 1)
        && (timecap == null || timecap! >= 1)
        && validateMetconType();
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
      timecap: r[Keys.timecap] as int?,
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
      Keys.metconType: MetconType.values.indexOf(o.metconType),
      Keys.rounds: o.rounds,
      Keys.timecap: o.timecap,
      Keys.description: o.description,
      Keys.deleted: o.deleted ? 1 : 0,
    };
  }
}