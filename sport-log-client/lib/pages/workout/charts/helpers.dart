import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

FlLine Function(double value) gridLineDrawer(BuildContext context) {
  return (value) => FlLine(
        color: Theme.of(context).colorScheme.primary,
        strokeWidth: 0.3,
        dashArray: [4, 4],
      );
}

class ChartValue {
  final DateTime datetime;
  final double value;

  ChartValue(this.datetime, this.value);

  @override
  String toString() => "$datetime: $value";
}
