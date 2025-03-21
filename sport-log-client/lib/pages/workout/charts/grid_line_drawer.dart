import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

FlLine Function(double value) gridLineDrawer() {
  return (value) =>
      const FlLine(color: Colors.grey, strokeWidth: 0.3, dashArray: [4, 4]);
}
