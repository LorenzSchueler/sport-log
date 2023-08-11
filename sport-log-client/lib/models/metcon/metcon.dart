import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';
import 'package:sport_log/models/clone_extensions.dart';
import 'package:sport_log/models/entity_interfaces.dart';
import 'package:sport_log/settings.dart';

part 'metcon.g.dart';

enum MetconType {
  @JsonValue("Amrap")
  amrap("Amrap"),
  @JsonValue("Emom")
  emom("Emom"),
  @JsonValue("ForTime")
  forTime("For Time");

  const MetconType(this.name);

  final String name;
}

@JsonSerializable(constructor: "_")
class Metcon extends AtomicEntity {
  Metcon({
    required this.id,
    required this.isDefaultMetcon,
    required this.name,
    required this.metconType,
    required this.rounds,
    required this.timecap,
    required this.description,
    required this.deleted,
  });

  Metcon._({
    required this.id,
    required Int64? userId,
    required this.name,
    required this.metconType,
    required this.rounds,
    required this.timecap,
    required this.description,
    required this.deleted,
  }) : isDefaultMetcon = userId == null;

  Metcon.defaultValue()
      : id = randomId(),
        isDefaultMetcon = false,
        name = "",
        metconType = MetconType.amrap,
        rounds = null,
        timecap = timecapDefaultValue,
        description = null,
        deleted = false;

  factory Metcon.fromJson(Map<String, dynamic> json) => _$MetconFromJson(json);

  @override
  @IdConverter()
  Int64 id;
  @Deprecated("Use isDefaultMetcon instead")
  @JsonKey(includeToJson: true)
  @OptionalIdConverter()
  Int64? get userId => isDefaultMetcon ? null : Settings.instance.userId!;
  @JsonKey(includeFromJson: false)
  bool isDefaultMetcon;
  String name;
  MetconType metconType;
  int? rounds;
  @OptionalDurationConverter()
  Duration? timecap;
  String? description;
  @override
  bool deleted;

  static const timecapDefaultValue = Duration(minutes: 30);
  static const roundsDefaultValue = 3;

  @override
  Map<String, dynamic> toJson() => _$MetconToJson(this);

  @override
  Metcon clone() => Metcon(
        id: id.clone(),
        isDefaultMetcon: isDefaultMetcon,
        name: name,
        metconType: metconType,
        rounds: rounds,
        timecap: timecap?.clone(),
        description: description,
        deleted: deleted,
      );

  bool validateMetconType() {
    return switch (metconType) {
      MetconType.amrap =>
        validate(rounds == null, 'Metcon: amrap: rounds != null') &&
            validate(timecap != null, 'Metcon: amrap: timecap == null'),
      MetconType.emom =>
        validate(rounds != null, 'Metcon: emom: rounds == null') &&
            validate(timecap != null, 'Metcon: emom: timecap == null'),
      MetconType.forTime =>
        validate(rounds != null, 'Metcon: forTime: rounds == null'),
    };
  }

  @override
  bool isValidBeforeSanitation() {
    return validate(!deleted, 'Metcon: deleted == true') &&
        validate(
          name.length >= 2 && name.length <= 80,
          'Metcon: name.length is < 2 or > 80',
        ) &&
        validate(rounds == null || rounds! >= 1, 'Metcon: rounds < 1') &&
        validate(
          timecap == null || timecap! >= const Duration(milliseconds: 1),
          'Metcon: timecap < 1ms',
        ) &&
        validate(validateMetconType(), 'Metcon: metcon type validation failed');
  }

  @override
  bool isValid() {
    return isValidBeforeSanitation() &&
        validate(
          description == null || description!.isNotEmpty,
          'Metcon: description is empty but not null',
        );
  }

  @override
  void sanitize() {
    if (description != null && description!.isEmpty) {
      description = null;
    }
  }
}

class DbMetconSerializer extends DbSerializer<Metcon> {
  @override
  Metcon fromDbRecord(DbRecord r, {String prefix = ''}) {
    return Metcon(
      id: Int64(r[prefix + Columns.id]! as int),
      isDefaultMetcon: r[prefix + Columns.isDefaultMetcon]! as int == 1,
      name: r[prefix + Columns.name]! as String,
      metconType: MetconType.values[r[prefix + Columns.metconType]! as int],
      rounds: r[prefix + Columns.rounds] as int?,
      timecap: r[prefix + Columns.timecap] == null
          ? null
          : Duration(milliseconds: r[prefix + Columns.timecap]! as int),
      description: r[prefix + Columns.description] as String?,
      deleted: r[prefix + Columns.deleted]! as int == 1,
    );
  }

  @override
  DbRecord toDbRecord(Metcon o) {
    return {
      Columns.id: o.id.toInt(),
      Columns.isDefaultMetcon: o.isDefaultMetcon ? 1 : 0,
      Columns.name: o.name,
      Columns.metconType: o.metconType.index,
      Columns.rounds: o.rounds,
      Columns.timecap: o.timecap?.inMilliseconds,
      Columns.description: o.description,
      Columns.deleted: o.deleted ? 1 : 0,
    };
  }
}
