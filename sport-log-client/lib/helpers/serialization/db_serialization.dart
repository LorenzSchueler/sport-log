import 'dart:typed_data';

import 'package:sport_log/models/cardio/all.dart';

class DbDurationListConverter {
  const DbDurationListConverter._() : super();

  static List<Duration>? mapToDart(Uint8List? fromDb) {
    assert(fromDb == null || fromDb.length % 8 == 0);
    if (fromDb == null) {
      return null;
    }
    final list = <int>[];
    for (var index = 0; index < fromDb.length; index += 8) {
      list.add(ByteData.sublistView(fromDb).getInt64(index, Endian.host));
    }
    return list.map((e) => Duration(milliseconds: e)).toList();
  }

  static Uint8List? mapToSql(List<Duration>? value) {
    return value == null
        ? null
        : Int64List.fromList(value.map((e) => e.inMilliseconds).toList())
            .buffer
            .asUint8List();
  }
}

class DbPositionListConverter {
  const DbPositionListConverter._() : super();

  static List<Position>? mapToDart(Uint8List? fromDb) {
    if (fromDb == null) {
      return null;
    }
    assert(fromDb.length % Position.byteSize == 0);
    final positions = <Position>[];
    for (var i = 0; i < fromDb.length; i += Position.byteSize) {
      positions.add(
        Position.fromBytesList(fromDb.sublist(i, i + Position.byteSize)),
      );
    }
    return positions;
  }

  static Uint8List? mapToSql(List<Position>? value) {
    if (value == null) {
      return null;
    }
    final bytes = Uint8List(value.length * Position.byteSize);
    var pos = 0;
    for (final position in value) {
      bytes.setAll(pos, position.asBytesList());
      pos += Position.byteSize;
    }
    return bytes;
  }
}
