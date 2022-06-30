import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

FlLine Function(double value) gridLineDrawer({
  required BuildContext context,
  Color? color,
}) {
  return (value) => FlLine(
        color: color ?? Theme.of(context).colorScheme.primary,
        strokeWidth: 0.3,
        dashArray: [4, 4],
      );
}
