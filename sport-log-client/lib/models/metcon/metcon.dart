import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';
import 'package:sport_log/models/clone_extensions.dart';
import 'package:sport_log/models/entity_interfaces.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/app_icons.dart';

part 'metcon.g.dart';

enum MetconType {
  @JsonValue("Amrap")
  amrap,
  @JsonValue("Emom")
  emom,
  @JsonValue("ForTime")
  forTime
}

extension ToIcon on MetconType {
  IconData get icon {
    switch (this) {
      case MetconType.amrap:
        return AppIcons.timeInterval;
      case MetconType.emom:
        return AppIcons.repeat;
      case MetconType.forTime:
        return AppIcons.timer;
    }
  }
}

extension ToDisplayName on MetconType {
  String get displayName {
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
class Metcon extends AtomicEntity {
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
  String name;
  MetconType metconType;
  int? rounds;
  @OptionalDurationConverter()
  Duration? timecap;
  String? description;
  @override
  bool deleted;

  static const Duration timecapDefaultValue = Duration(minutes: 30);
  static const int roundsDefaultValue = 3;

  Metcon.defaultValue()
      : id = randomId(),
        userId = Settings.userId,
        name = "",
        metconType = MetconType.amrap,
        rounds = null,
        timecap = timecapDefaultValue,
        description = null,
        deleted = false;

  factory Metcon.fromJson(Map<String, dynamic> json) => _$MetconFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$MetconToJson(this);

  @override
  Metcon clone() => Metcon(
        id: id.clone(),
        userId: userId?.clone(),
        name: name,
        metconType: metconType,
        rounds: rounds,
        timecap: timecap?.clone(),
        description: description,
        deleted: deleted,
      );

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
    return validate(!deleted, 'Metcon: deleted == true') &&
        validate(userId != null, 'Metcon: userId == null') &&
        validate(
          name.length >= 2 && name.length <= 80,
          'Metcon: name.length is < 2 or > 80',
        ) &&
        validate(rounds == null || rounds! >= 1, 'Metcon: rounds < 1') &&
        validate(
          timecap == null || timecap! >= const Duration(milliseconds: 1),
          'Metcon: timecap < 1ms',
        ) &&
        validate(
          description == null || description!.isNotEmpty,
          'Metcon: description is empty but not null',
        ) &&
        validate(validateMetconType(), 'Metcon: metcon type validation failed');
  }
}

class DbMetconSerializer extends DbSerializer<Metcon> {
  @override
  Metcon fromDbRecord(DbRecord r, {String prefix = ''}) {
    return Metcon(
      id: Int64(r[prefix + Columns.id]! as int),
      userId: r[prefix + Columns.userId] == null
          ? null
          : Int64(r[prefix + Columns.userId]! as int),
      name: r[prefix + Columns.name] as String,
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
      Columns.userId: o.userId?.toInt(),
      Columns.name: o.name,
      Columns.metconType: o.metconType.index,
      Columns.rounds: o.rounds,
      Columns.timecap: o.timecap?.inMilliseconds,
      Columns.description: o.description,
      Columns.deleted: o.deleted ? 1 : 0,
    };
  }
}
