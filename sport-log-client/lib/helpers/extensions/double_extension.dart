import 'dart:math';

extension DateTimeExtension on double {
  double roundToPrecision(int precision) {
    final factor = pow(10, precision);
    return (this * factor).round() / factor;
  }
}
