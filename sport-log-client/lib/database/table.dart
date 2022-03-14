enum DbType { integer, text, real, blob, bool }

enum OnAction { setNull, setDefault, cascade, restrict, noAction }

class Column {
  Column.int(this.name) : type = DbType.integer;
  Column.text(this.name) : type = DbType.text;
  Column.real(this.name) : type = DbType.real;
  Column.blob(this.name) : type = DbType.blob;
  Column.bool(this.name) : type = DbType.bool;

  final String name;
  final DbType type;
  bool _nonNull = true;
  bool _isPrimaryKey = false;
  String? _defaultValue;
  String? _referenceTable;
  String? _referenceColumn;
  OnAction? _onUpdateReference;
  OnAction? _onDeleteReference;
  String? _check;

  void nullable() {
    _nonNull = false;
  }

  void primaryKey() {
    _isPrimaryKey = true;
  }

  void withDefault(String value) {
    _defaultValue = value;
  }

  void references(
    String table, {
    String? column,
    required OnAction? onDelete,
    OnAction? onUpdate,
  }) {
    _referenceTable = table;
    _referenceColumn = column;
    _onDeleteReference = onDelete;
    _onUpdateReference = onUpdate;
  }

  void checkBetween(dynamic start, dynamic end) {
    _check = "$name between $start and $end";
  }

  void checkIn(List<dynamic> values) {
    _check = "$name in (${values.join(',')})";
  }

  void checkGt(dynamic value) {
    _check = "$name > $value";
  }

  void checkGe(dynamic value) {
    _check = "$name >= $value";
  }

  void checkLt(dynamic value) {
    _check = "$name < $value";
  }

  void checkLe(dynamic value) {
    _check = "$name <= $value";
  }

  void checkLengthGe(int value) {
    _check = "length($name) >= $value";
  }

  void checkLengthLe(int value) {
    _check = "length($name) <= $value";
  }

  void checkLengthBetween(int start, int end) {
    _check = "length($name) between $start and $end";
  }

  bool getIsPrimaryKey() => _isPrimaryKey;

  static String _typeToString(DbType type) {
    switch (type) {
      case DbType.integer:
        return 'integer';
      case DbType.text:
        return 'text';
      case DbType.real:
        return 'real';
      case DbType.blob:
        return 'blob';
      case DbType.bool:
        return 'integer';
    }
  }

  static String _onActionToString(OnAction action) {
    switch (action) {
      case OnAction.setNull:
        return 'set null';
      case OnAction.setDefault:
        return 'set default';
      case OnAction.cascade:
        return 'cascade';
      case OnAction.restrict:
        return 'restrict';
      case OnAction.noAction:
        return 'no action';
    }
  }

  String get _referenceString {
    if (_referenceTable == null) {
      return '';
    }
    final String referenceName = _referenceColumn == null
        ? _referenceTable!
        : '${_referenceTable!}(${_referenceColumn!})';
    final onUpdateStr = _onUpdateReference == null
        ? ''
        : ' on update ${_onActionToString(_onUpdateReference!)}';
    final onDeleteStr = _onDeleteReference == null
        ? ''
        : 'on delete ${_onActionToString(_onDeleteReference!)}';
    return 'references $referenceName $onDeleteStr'.trimRight() + onUpdateStr;
  }

  String setUpSql() {
    assert(name.isNotEmpty);
    if (_check == null && type == DbType.bool) {
      _check = '$name in (0, 1)';
    }
    final typeStr = _typeToString(type);
    final nonNullStr = _nonNull ? 'not null' : '';
    final defaultValueStr =
        _defaultValue == null ? '' : 'default(${_defaultValue!})';
    final checkStr = _check == null ? '' : 'check(${_check!})';
    return [
      name,
      typeStr,
      nonNullStr,
      defaultValueStr,
      _referenceString,
      checkStr
    ].where((s) => s.isNotEmpty).join(' ');
  }
}

class UniqueIndex {
  final String tableName;
  final List<String> columns;

  const UniqueIndex(this.tableName, this.columns) : super();

  String get setupSql {
    return 'create unique index ${tableName}__${columns.join('__')}__idx '
        'on $tableName (${columns.join(', ')}) where deleted = 0;';
  }
}

class Table {
  Table({
    required this.name,
    required this.columns,
    required List<List<String>> uniqueColumns,
    this.rawSql = const [],
  })  : uniqueIndices = uniqueColumns.map((c) => UniqueIndex(name, c)).toList(),
        prefix = name + '__';

  final String prefix;
  final String name;
  final List<Column> columns;
  final List<UniqueIndex> uniqueIndices;
  final List<String> rawSql;

  List<String> get setupSql {
    final primaryKey =
        columns.where((c) => c.getIsPrimaryKey()).map((c) => c.name).toList();
    final primaryKeyStr =
        primaryKey.isEmpty ? '' : 'primary key(${primaryKey.join(', ')})';
    final tableSetup = '''create table $name (
      ${[
      ...columns.map((c) => c.setUpSql()),
      primaryKeyStr,
    ].map((s) => '\t' + s).join(',\n')}
    );
    ''';
    final uniqueIndicesSetup = uniqueIndices.map((u) => u.setupSql);
    final updateTrigger =
        '''create trigger ${name}_update before update on $name
    begin
      update $name set sync_status = 1 where id = new.id and sync_status = 0;
    end;
    ''';

    return [tableSetup, ...uniqueIndicesSetup, updateTrigger, ...rawSql];
  }

  // used for select statement
  String get allColumns {
    return columns.map((c) => '$name.${c.name} AS $prefix${c.name}').join(', ');
  }
}

abstract class Tables {
  static const action = 'action';
  static const actionEvent = 'action_event';
  static const actionProvider = 'action_provider';
  static const actionRule = 'action_rule';
  static const cardioSession = 'cardio_session';
  static const diary = 'diary';
  static const eorm = 'eorm';
  static const metcon = 'metcon';
  static const metconMovement = 'metcon_movement';
  static const metconSession = 'metcon_session';
  static const movement = 'movement';
  static const platform = 'platform';
  static const platformCredential = 'platform_credential';
  static const route = 'route';
  static const strengthSession = 'strength_session';
  static const strengthSet = 'strength_set';
  static const wod = 'wod';
}

abstract class Columns {
  static const actionId = 'action_id';
  static const actionProviderId = 'action_provider_id';
  static const arguments = 'arguments';
  static const ascent = 'ascent';
  static const avgCadence = 'avg_cadence';
  static const avgCount = 'avg_count';
  static const avgHeartRate = 'avg_heart_rate';
  static const bodyweight = 'bodyweight';
  static const cadence = 'cadence';
  static const calories = 'calories';
  static const cardio = 'cardio';
  static const cardioType = 'cardio_type';
  static const comments = 'comments';
  static const count = 'count';
  static const createBefore = 'create_before';
  static const date = 'date';
  static const datetime = 'datetime';
  static const deleteAfter = 'delete_after';
  static const deleted = 'deleted';
  static const descent = 'descent';
  static const description = 'description';
  static const dimension = 'dimension';
  static const distance = 'distance';
  static const distanceUnit = 'distance_unit';
  static const enabled = 'enabled';
  static const eormPercentage = 'eorm_percentage';
  static const eormReps = 'eorm_reps';
  static const femaleWeight = 'female_weight';
  static const heartRate = 'heart_rate';
  static const id = 'id';
  static const interval = 'interval';
  static const maleWeight = 'male_weight';
  static const markedPositions = 'marked_positions';
  static const maxCount = 'max_count';
  static const maxEorm = 'max_eorm';
  static const maxWeight = 'max_weight';
  static const metconId = 'metcon_id';
  static const metconType = 'metcon_type';
  static const minCount = 'min_count';
  static const movementId = 'movement_id';
  static const movementNumber = 'movement_number';
  static const name = 'name';
  static const numSets = 'num_sets';
  static const password = 'password';
  static const platformId = 'platform_id';
  static const reps = 'reps';
  static const rounds = 'rounds';
  static const routeId = 'route_id';
  static const rx = 'rx';
  static const setNumber = 'set_number';
  static const strengthSessionId = 'strength_session_id';
  static const sumCount = 'sum_count';
  static const sumVolume = 'sum_volume';
  static const syncNeeded = 'sync_needed';
  static const syncStatus = 'sync_status';
  static const time = 'time';
  static const timecap = 'timecap';
  static const track = 'track';
  static const userId = 'user_id';
  static const username = 'username';
  static const weekday = 'weekday';
  static const weight = 'weight';
}
