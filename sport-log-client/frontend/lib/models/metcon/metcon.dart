
import 'package:json_annotation/json_annotation.dart';

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
class Metcon {
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

  int id;
  int? userId;
  String? name;
  MetconType metconType;
  int? rounds;
  int? timecap;
  String? description;
  bool deleted;

  factory Metcon.fromJson(Map<String, dynamic> json) => _$MetconFromJson(json);
  Map<String, dynamic> toJson() => _$MetconToJson(this);
}