
import 'dart:math';

import 'package:fixnum/fixnum.dart';

final Random _random = Random.secure();
const randomMax = 0x100000000; // u32 max + 1

extension on Random {
  Int64 nextId() {
    final i1 = _random.nextInt(randomMax);
    final i2 = _random.nextInt(randomMax);
    return Int64.fromInts(i1, i2);
  }
}

Int64 randomId() {
  return _random.nextId();
}