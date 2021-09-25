import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/helpers/theme.dart';

FlLine Function(double value) gridLineDrawer(BuildContext context) {
  return (value) => FlLine(
        color: primaryVariantOf(context),
        strokeWidth: 0.3,
        dashArray: [8, 4],
      );
}
