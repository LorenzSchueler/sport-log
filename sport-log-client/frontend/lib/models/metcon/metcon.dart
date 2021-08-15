
import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:moor/moor.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/helpers/json_serialization.dart';
import 'package:sport_log/helpers/update_validatable.dart';

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
class Metcon extends Insertable<Metcon> implements UpdateValidatable {
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

  @IdConverter() Int64 id;
  @OptionalIdConverter() Int64? userId;
  String? name;
  MetconType metconType;
  int? rounds;
  int? timecap;
  String? description;
  bool deleted;

  factory Metcon.fromJson(Map<String, dynamic> json) => _$MetconFromJson(json);
  Map<String, dynamic> toJson() => _$MetconToJson(this);

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    return MetconsCompanion(
      id: Value(id),
      userId: Value(userId),
      name: Value(name),
      metconType: Value(metconType),
      rounds: Value(rounds),
      timecap: Value(timecap),
      description: Value(description),
      deleted: Value(deleted),
    ).toColumns(false);
  }

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
  bool validateOnUpdate() {
    return userId != null
        && name != null
        && deleted != true
        && (rounds == null || rounds! >= 1)
        && (timecap == null || timecap! >= 1)
        && validateMetconType();
  }
}