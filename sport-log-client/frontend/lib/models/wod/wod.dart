
import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/defs.dart';
import 'package:sport_log/helpers/json_serialization.dart';

part 'wod.g.dart';

@JsonSerializable()
class Wod implements DbObject {
  Wod({
    required this.id,
    required this.userId,
    required this.date,
    required this.description,
    required this.deleted,
  });

  @override
  @IdConverter() Int64 id;
  @IdConverter() Int64 userId;
  @DateConverter() DateTime date;
  String? description;
  @override
  bool deleted;

  factory Wod.fromJson(Map<String, dynamic> json) => _$WodFromJson(json);
  Map<String, dynamic> toJson() => _$WodToJson(this);

  @override
  bool isValid() {
    return !deleted;
  }
}