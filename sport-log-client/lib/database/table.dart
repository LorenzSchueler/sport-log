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
  bool _isUnique = false;
  String? _defaultValue;
  String? _referenceTable;
  String? _referenceColumn;
  OnAction? _onUpdateReference;
  OnAction? _onDeleteReference;
  String? _check;

  Column nullable() {
    _nonNull = false;
    return this;
  }

  Column primaryKey() {
    _isPrimaryKey = true;
    return this;
  }

  Column unique() {
    _isUnique = true;
    return this;
  }

  Column withDefault(String value) {
    _defaultValue = value;
    return this;
  }

  Column references(String table,
      {String? column, OnAction? onDelete, OnAction? onUpdate}) {
    _referenceTable = table;
    _referenceColumn = column;
    _onDeleteReference = onDelete;
    _onUpdateReference = onUpdate;
    return this;
  }

  Column checkBetween(dynamic start, dynamic end) {
    _check = "$name between $start and $end";
    return this;
  }

  Column checkIn(List<dynamic> values) {
    _check = "$name in (${values.join(',')})";
    return this;
  }

  Column checkGt(dynamic value) {
    _check = "$name > $value";
    return this;
  }

  Column checkGe(dynamic value) {
    _check = "$name >= $value";
    return this;
  }

  Column checkLt(dynamic value) {
    _check = "$name < $value";
    return this;
  }

  Column checkLe(dynamic value) {
    _check = "$name <= $value";
    return this;
  }

  Column checkLengthGe(int value) {
    _check = "length($name) >= $value";
    return this;
  }

  Column checkLengthLe(int value) {
    _check = "length($name) <= $value";
    return this;
  }

  Column checkLengthBetween(int start, int end) {
    _check = "length($name) between $start and $end";
    return this;
  }

  bool getIsPrimaryKey() => _isPrimaryKey;

  static String _typeToString(DbType type) {
    switch (type) {
      case DbType.integer:
        return 'INTEGER';
      case DbType.text:
        return 'TEXT';
      case DbType.real:
        return 'REAL';
      case DbType.blob:
        return 'BLOB';
      case DbType.bool:
        return 'INTEGER';
    }
  }

  static String _onActionToString(OnAction action) {
    switch (action) {
      case OnAction.setNull:
        return 'SET NULL';
      case OnAction.setDefault:
        return 'SET DEFAULT';
      case OnAction.cascade:
        return 'CASCADE';
      case OnAction.restrict:
        return 'RESTRICT';
      case OnAction.noAction:
        return 'NO ACTION';
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
        : ' ON UPDATE ${_onActionToString(_onUpdateReference!)}';
    final onDeleteStr = _onDeleteReference == null
        ? ''
        : 'ON DELETE ${_onActionToString(_onDeleteReference!)}';
    return 'REFERENCES $referenceName $onDeleteStr'.trimRight() + onUpdateStr;
  }

  String setUpSql() {
    assert(name.isNotEmpty);
    if (_check == null && type == DbType.bool) {
      _check = '$name in (0, 1)';
    }
    final typeStr = _typeToString(type);
    final nonNullStr = _nonNull ? 'NOT NULL' : '';
    final uniqueStr = _isUnique ? 'UNIQUE' : '';
    final defaultValueStr =
        _defaultValue == null ? '' : 'DEFAULT(${_defaultValue!})';
    final checkStr = _check == null ? '' : 'CHECK(${_check!})';
    return [
      name,
      typeStr,
      nonNullStr,
      uniqueStr,
      defaultValueStr,
      _referenceString,
      checkStr
    ].where((s) => s.isNotEmpty).join(' ');
  }
}

abstract class Constraint {
  const Constraint();

  String setupSql();
}

class Unique extends Constraint {
  const Unique(this.columns) : super();
  final List<String> columns;

  @override
  String setupSql() {
    return 'UNIQUE (${columns.join(', ')})';
  }
}

class Table {
  Table(
    this.name, {
    required this.columns,
    List<Constraint>? withConstraints,
  })  : constraints = withConstraints ?? [],
        prefix = name + '__';

  final List<Column> columns;
  final String name;
  final String prefix;
  final List<Constraint> constraints;

  String setupSql() {
    final primaryKey =
        columns.where((c) => c.getIsPrimaryKey()).map((c) => c.name).toList();
    final primaryKeyStr =
        primaryKey.isEmpty ? '' : 'PRIMARY KEY(${primaryKey.join(', ')})';
    return '''
    CREATE TABLE $name (
      ${[
      ...columns.map((c) => c.setUpSql()),
      primaryKeyStr,
      ...constraints.map((c) => c.setupSql()),
    ].map((s) => '\t' + s).join(',\n')}
    );
    ''';
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
  static const heartRate = 'heart_rate';
  static const id = 'id';
  static const interval = 'interval';
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
