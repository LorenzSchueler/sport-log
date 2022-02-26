import 'dart:math';

import 'package:fixnum/fixnum.dart';

final Random _random = Random.secure();
const _randomMax = 0x100000000; // u32 max + 1

extension on Random {
  Int64 nextId() {
    final i1 = _random.nextInt(_randomMax);
    final i2 = _random.nextInt(_randomMax);
    final result = Int64.fromInts(i1, i2);
    assert(result.bitLength <= 64);
    return result;
  }
}

Int64 randomId() {
  return _random.nextId();
}
