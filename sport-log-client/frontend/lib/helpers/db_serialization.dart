

import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:moor/moor.dart';
import 'package:sport_log/models/cardio/all.dart';

class DbIdConverter extends TypeConverter<Int64, int> {
  const DbIdConverter() : super();

  @override
  Int64? mapToDart(int? fromDb) {
    return fromDb == null ? null : Int64(fromDb);
  }

  @override
  int? mapToSql(Int64? value) {
    return value?.toInt();
  }
}

class DbDoubleListConverter extends TypeConverter<List<double>, Uint8List> {
  @override
  List<double>? mapToDart(Uint8List? fromDb) {
    assert(fromDb == null || fromDb.length % 8 == 0);
    return fromDb?.buffer.asFloat64List().toList();
  }

  @override
  Uint8List? mapToSql(List<double>? value) {
    return value == null
        ? null
        : Float64List.fromList(value).buffer.asUint8List();
  }
}

class DbPositionListConverter extends TypeConverter<List<Position>, Uint8List> {
  @override
  List<Position>? mapToDart(Uint8List? fromDb) {
    if (fromDb == null) {
      return null;
    }
    assert(fromDb.length % Position.byteSize == 0);
    final List<Position> positions = [];
    for (int i = 0; i < fromDb.length; i += Position.byteSize) {
      positions.add(
          Position.fromBytesList(fromDb.sublist(i, i + Position.byteSize)));
    }
    return positions;
  }

  @override
  Uint8List? mapToSql(List<Position>? value) {
    if (value == null) {
      return null;
    }
    final bytes = Uint8List(value.length * Position.byteSize);
    for (final position in value) {
      bytes.addAll(position.asBytesList());
    }
    return bytes;
  }
}
