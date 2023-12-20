import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';
import 'package:sport_log/models/clone_extensions.dart';
import 'package:sport_log/models/entity_interfaces.dart';
import 'package:sport_log/settings.dart';

part 'wod.g.dart';

@JsonSerializable()
class Wod extends AtomicEntity {
  Wod({
    required this.id,
    required this.date,
    required this.description,
    required this.deleted,
  });

  Wod.defaultValue()
      : id = randomId(),
        date = DateTime.now(),
        description = null,
        deleted = false;

  factory Wod.fromJson(Map<String, dynamic> json) => _$WodFromJson(json);

  @override
  @IdConverter()
  Int64 id;
  @JsonKey(includeToJson: true, name: "user_id")
  @IdConverter()
  Int64 get _userId => Settings.instance.userId!;
  @DateConverter()
  DateTime date;
  String? description;
  @override
  bool deleted;

  @override
  Map<String, dynamic> toJson() => _$WodToJson(this);

  @override
  Wod clone() => Wod(
        id: id.clone(),
        date: date.clone(),
        description: description,
        deleted: deleted,
      );

  @override
  bool isValidBeforeSanitation() {
    return validate(!deleted, 'Wod: deleted == true');
  }

  @override
  bool isValid() {
    return isValidBeforeSanitation() &&
        validate(
          description == null || description!.isNotEmpty,
          "Wod: description is empty but not null",
        );
  }

  @override
  void sanitize() {
    if (description != null && description!.isEmpty) {
      description = null;
    }
  }
}

class DbWodSerializer extends DbSerializer<Wod> {
  @override
  Wod fromDbRecord(DbRecord r, {String prefix = ''}) {
    return Wod(
      id: Int64(r[prefix + Columns.id]! as int),
      date: DateTime.parse(r[prefix + Columns.date]! as String),
      description: r[prefix + Columns.description] as String?,
      deleted: r[prefix + Columns.deleted]! as int == 1,
    );
  }

  @override
  DbRecord toDbRecord(Wod o) {
    return {
      Columns.id: o.id.toInt(),
      Columns.date: o.date.toString(),
      Columns.description: o.description,
      Columns.deleted: o.deleted ? 1 : 0,
    };
  }
}
