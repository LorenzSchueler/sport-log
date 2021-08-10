// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// **************************************************************************
// MoorGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps, unnecessary_this
class MetconsCompanion extends UpdateCompanion<Metcon> {
  final Value<Int64> id;
  final Value<Int64?> userId;
  final Value<String?> name;
  final Value<MetconType> metconType;
  final Value<int?> rounds;
  final Value<int?> timecap;
  final Value<String?> description;
  final Value<bool> deleted;
  final Value<DateTime> lastModified;
  final Value<bool> isNew;
  const MetconsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.metconType = const Value.absent(),
    this.rounds = const Value.absent(),
    this.timecap = const Value.absent(),
    this.description = const Value.absent(),
    this.deleted = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.isNew = const Value.absent(),
  });
  MetconsCompanion.insert({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    required MetconType metconType,
    this.rounds = const Value.absent(),
    this.timecap = const Value.absent(),
    this.description = const Value.absent(),
    required bool deleted,
    this.lastModified = const Value.absent(),
    this.isNew = const Value.absent(),
  })  : metconType = Value(metconType),
        deleted = Value(deleted);
  static Insertable<Metcon> custom({
    Expression<Int64>? id,
    Expression<Int64?>? userId,
    Expression<String?>? name,
    Expression<MetconType>? metconType,
    Expression<int?>? rounds,
    Expression<int?>? timecap,
    Expression<String?>? description,
    Expression<bool>? deleted,
    Expression<DateTime>? lastModified,
    Expression<bool>? isNew,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (metconType != null) 'metcon_type': metconType,
      if (rounds != null) 'rounds': rounds,
      if (timecap != null) 'timecap': timecap,
      if (description != null) 'description': description,
      if (deleted != null) 'deleted': deleted,
      if (lastModified != null) 'last_modified': lastModified,
      if (isNew != null) 'is_new': isNew,
    });
  }

  MetconsCompanion copyWith(
      {Value<Int64>? id,
      Value<Int64?>? userId,
      Value<String?>? name,
      Value<MetconType>? metconType,
      Value<int?>? rounds,
      Value<int?>? timecap,
      Value<String?>? description,
      Value<bool>? deleted,
      Value<DateTime>? lastModified,
      Value<bool>? isNew}) {
    return MetconsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      metconType: metconType ?? this.metconType,
      rounds: rounds ?? this.rounds,
      timecap: timecap ?? this.timecap,
      description: description ?? this.description,
      deleted: deleted ?? this.deleted,
      lastModified: lastModified ?? this.lastModified,
      isNew: isNew ?? this.isNew,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      final converter = $MetconsTable.$converter0;
      map['id'] = Variable<int>(converter.mapToSql(id.value)!);
    }
    if (userId.present) {
      final converter = $MetconsTable.$converter1;
      map['user_id'] = Variable<int?>(converter.mapToSql(userId.value));
    }
    if (name.present) {
      map['name'] = Variable<String?>(name.value);
    }
    if (metconType.present) {
      final converter = $MetconsTable.$converter2;
      map['metcon_type'] = Variable<int>(converter.mapToSql(metconType.value)!);
    }
    if (rounds.present) {
      map['rounds'] = Variable<int?>(rounds.value);
    }
    if (timecap.present) {
      map['timecap'] = Variable<int?>(timecap.value);
    }
    if (description.present) {
      map['description'] = Variable<String?>(description.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    if (isNew.present) {
      map['is_new'] = Variable<bool>(isNew.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MetconsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('metconType: $metconType, ')
          ..write('rounds: $rounds, ')
          ..write('timecap: $timecap, ')
          ..write('description: $description, ')
          ..write('deleted: $deleted, ')
          ..write('lastModified: $lastModified, ')
          ..write('isNew: $isNew')
          ..write(')'))
        .toString();
  }
}

class $MetconsTable extends Metcons with TableInfo<$MetconsTable, Metcon> {
  final GeneratedDatabase _db;
  final String? _alias;
  $MetconsTable(this._db, [this._alias]);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumnWithTypeConverter<Int64, int?> id =
      GeneratedColumn<int?>('id', aliasedName, false,
              typeName: 'INTEGER', requiredDuringInsert: false)
          .withConverter<Int64>($MetconsTable.$converter0);
  final VerificationMeta _userIdMeta = const VerificationMeta('userId');
  late final GeneratedColumnWithTypeConverter<Int64, int?> userId =
      GeneratedColumn<int?>('user_id', aliasedName, true,
              typeName: 'INTEGER', requiredDuringInsert: false)
          .withConverter<Int64>($MetconsTable.$converter1);
  final VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String?> name = GeneratedColumn<String?>(
      'name', aliasedName, true,
      typeName: 'TEXT', requiredDuringInsert: false);
  final VerificationMeta _metconTypeMeta = const VerificationMeta('metconType');
  late final GeneratedColumnWithTypeConverter<MetconType, int?> metconType =
      GeneratedColumn<int?>('metcon_type', aliasedName, false,
              typeName: 'INTEGER', requiredDuringInsert: true)
          .withConverter<MetconType>($MetconsTable.$converter2);
  final VerificationMeta _roundsMeta = const VerificationMeta('rounds');
  late final GeneratedColumn<int?> rounds = GeneratedColumn<int?>(
      'rounds', aliasedName, true,
      typeName: 'INTEGER', requiredDuringInsert: false);
  final VerificationMeta _timecapMeta = const VerificationMeta('timecap');
  late final GeneratedColumn<int?> timecap = GeneratedColumn<int?>(
      'timecap', aliasedName, true,
      typeName: 'INTEGER', requiredDuringInsert: false);
  final VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  late final GeneratedColumn<String?> description = GeneratedColumn<String?>(
      'description', aliasedName, true,
      typeName: 'TEXT', requiredDuringInsert: false);
  final VerificationMeta _deletedMeta = const VerificationMeta('deleted');
  late final GeneratedColumn<bool?> deleted = GeneratedColumn<bool?>(
      'deleted', aliasedName, false,
      typeName: 'INTEGER',
      requiredDuringInsert: true,
      defaultConstraints: 'CHECK (deleted IN (0, 1))');
  final VerificationMeta _lastModifiedMeta =
      const VerificationMeta('lastModified');
  late final GeneratedColumn<DateTime?> lastModified =
      GeneratedColumn<DateTime?>('last_modified', aliasedName, false,
          typeName: 'INTEGER',
          requiredDuringInsert: false,
          clientDefault: () => DateTime.now());
  final VerificationMeta _isNewMeta = const VerificationMeta('isNew');
  late final GeneratedColumn<bool?> isNew = GeneratedColumn<bool?>(
      'is_new', aliasedName, false,
      typeName: 'INTEGER',
      requiredDuringInsert: false,
      defaultConstraints: 'CHECK (is_new IN (0, 1))',
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        name,
        metconType,
        rounds,
        timecap,
        description,
        deleted,
        lastModified,
        isNew
      ];
  @override
  String get aliasedName => _alias ?? 'metcons';
  @override
  String get actualTableName => 'metcons';
  @override
  VerificationContext validateIntegrity(Insertable<Metcon> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    context.handle(_idMeta, const VerificationResult.success());
    context.handle(_userIdMeta, const VerificationResult.success());
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    context.handle(_metconTypeMeta, const VerificationResult.success());
    if (data.containsKey('rounds')) {
      context.handle(_roundsMeta,
          rounds.isAcceptableOrUnknown(data['rounds']!, _roundsMeta));
    }
    if (data.containsKey('timecap')) {
      context.handle(_timecapMeta,
          timecap.isAcceptableOrUnknown(data['timecap']!, _timecapMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('deleted')) {
      context.handle(_deletedMeta,
          deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta));
    } else if (isInserting) {
      context.missing(_deletedMeta);
    }
    if (data.containsKey('last_modified')) {
      context.handle(
          _lastModifiedMeta,
          lastModified.isAcceptableOrUnknown(
              data['last_modified']!, _lastModifiedMeta));
    }
    if (data.containsKey('is_new')) {
      context.handle(
          _isNewMeta, isNew.isAcceptableOrUnknown(data['is_new']!, _isNewMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Metcon map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Metcon(
      id: $MetconsTable.$converter0.mapToDart(const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}id']))!,
      userId: $MetconsTable.$converter1.mapToDart(const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}user_id'])),
      name: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}name']),
      metconType: $MetconsTable.$converter2.mapToDart(const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}metcon_type']))!,
      rounds: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}rounds']),
      timecap: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}timecap']),
      description: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}description']),
      deleted: const BoolType()
          .mapFromDatabaseResponse(data['${effectivePrefix}deleted'])!,
    );
  }

  @override
  $MetconsTable createAlias(String alias) {
    return $MetconsTable(_db, alias);
  }

  static TypeConverter<Int64, int> $converter0 = const DbIdConverter();
  static TypeConverter<Int64, int> $converter1 = const DbIdConverter();
  static TypeConverter<MetconType, int> $converter2 =
      const EnumIndexConverter<MetconType>(MetconType.values);
}

abstract class _$Database extends GeneratedDatabase {
  _$Database(QueryExecutor e) : super(SqlTypeSystem.defaultInstance, e);
  late final $MetconsTable metcons = $MetconsTable(this);
  late final MetconsDao metconsDao = MetconsDao(this as Database);
  @override
  Iterable<TableInfo> get allTables => allSchemaEntities.whereType<TableInfo>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [metcons];
}
