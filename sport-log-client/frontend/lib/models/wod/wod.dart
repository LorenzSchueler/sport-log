
import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:moor/moor.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/helpers/json_serialization.dart';
import 'package:sport_log/helpers/update_validatable.dart';

part 'wod.g.dart';

@JsonSerializable()
class Wod extends Insertable<Wod> implements UpdateValidatable {
  Wod({
    required this.id,
    required this.userId,
    required this.date,
    required this.description,
    required this.deleted,
  });

  @IdConverter() Int64 id;
  @IdConverter() Int64 userId;
  @DateConverter() DateTime date;
  String? description;
  bool deleted;

  factory Wod.fromJson(Map<String, dynamic> json) => _$WodFromJson(json);
  Map<String, dynamic> toJson() => _$WodToJson(this);

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    return WodsCompanion(
      id: Value(id),
      userId: Value(userId),
      date: Value(date),
      description: Value(description),
      deleted: Value(deleted),
    ).toColumns(false);
  }

  @override
  bool validateOnUpdate() {
    return !deleted;
  }
}