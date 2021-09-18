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

  Column check(String checkValue) {
    _check = checkValue;
    return this;
  }

  bool getIsPrimaryKey() => _isPrimaryKey;

  static String typeToString(DbType type) {
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

  static String onActionToString(OnAction action) {
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
        : ' ON UPDATE ${onActionToString(_onUpdateReference!)}';
    final onDeleteStr = _onDeleteReference == null
        ? ''
        : 'ON DELETE ${onActionToString(_onDeleteReference!)}';
    return 'REFERENCES $referenceName $onDeleteStr'.trimRight() + onUpdateStr;
  }

  String setUpSql() {
    assert(name.isNotEmpty);
    if (_check == null && type == DbType.bool) {
      _check = '$name in (0, 1)';
    }
    final typeStr = typeToString(type);
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

class Table {
  Table(this.name, {required List<Column> withColumns}) : columns = withColumns;

  List<Column> columns;
  String name;

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
    ].map((s) => '\t' + s).join(',\n')}
);
''';
  }

  // used for select statement
  String get allColumns {
    return columns.map((c) => '$name.${c.name}').join(', ');
  }
}
