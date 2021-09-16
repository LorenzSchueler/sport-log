import 'dart:math';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:sport_log/models/cardio/all.dart';
import 'package:sport_log/models/movement/all.dart';

class DbIdConverter {
  const DbIdConverter() : super();

  Int64? mapToDart(int? fromDb) {
    return fromDb == null ? null : Int64(fromDb);
  }

  int? mapToSql(Int64? value) {
    return value?.toInt();
  }
}

class DbDoubleListConverter {
  const DbDoubleListConverter() : super();

  List<double>? mapToDart(Uint8List? fromDb) {
    assert(fromDb == null || fromDb.length % 8 == 0);
    return fromDb?.buffer.asFloat64List().toList();
  }

  Uint8List? mapToSql(List<double>? value) {
    return value == null
        ? null
        : Float64List.fromList(value).buffer.asUint8List();
  }
}

class DbPositionListConverter {
  const DbPositionListConverter() : super();

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

  Uint8List? mapToSql(List<Position>? value) {
    if (value == null) {
      return null;
    }
    final bytes = Uint8List(value.length * Position.byteSize);
    int p = 0;
    for (final position in value) {
      bytes.setAll(p, position.asBytesList());
      p += Position.byteSize;
    }
    return bytes;
  }
}
