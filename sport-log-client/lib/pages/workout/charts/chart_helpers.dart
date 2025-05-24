import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

ExtraLinesData? touchLine(double? lastX) => lastX == null
    ? null
    : ExtraLinesData(
        verticalLines: [VerticalLine(x: lastX, color: Colors.white)],
      );

LineTouchData touchCallback(void Function(double?) callback) => LineTouchData(
  enabled: false,
  touchSpotThreshold: double.infinity, // always get nearest point
  touchCallback: (event, response) => _touchCallback(event, response, callback),
);

void _touchCallback(
  FlTouchEvent event,
  LineTouchResponse? response,
  void Function(double?) callback,
) {
  if (event is FlLongPressStart || event is FlLongPressMoveUpdate) {
    final xValues = response?.lineBarSpots?.map((e) => e.x).toList();
    final xValue = xValues == null || xValues.isEmpty
        ? null
        : xValues[xValues.length ~/ 2]; // median
    if (xValue != null) {
      callback(xValue);
    }
  } else if (event is FlLongPressEnd) {
    callback(null);
  }
}
