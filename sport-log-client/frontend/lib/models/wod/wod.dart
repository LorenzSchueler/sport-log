
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

class DbWodSerializer implements DbSerializer<Wod> {
  @override
  Wod fromDbRecord(DbRecord r) {
    return Wod(
      id: Int64(r[Keys.id]! as int),
      userId: Int64(r[Keys.userId]! as int),
      date: DateTime.parse(r[Keys.date]! as String),
      description: r[Keys.description] as String?,
      deleted: r[Keys.deleted]! as int == 1,
    );
  }

  @override
  DbRecord toDbRecord(Wod o) {
    return {
      Keys.id: o.id.toInt(),
      Keys.userId: o.userId.toInt(),
      Keys.date: o.date.toString(),
      Keys.description: o.description,
      Keys.deleted: o.deleted ? 1 : 0,
    };
  }
}