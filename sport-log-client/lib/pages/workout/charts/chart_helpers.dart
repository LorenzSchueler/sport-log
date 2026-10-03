import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';

ExtraLinesData? touchLine(double? lastX) => lastX == null
    ? null
    : ExtraLinesData(
        verticalLines: [VerticalLine(x: lastX, color: Colors.white)],
      );

/// Hides the titles fl_chart adds at the min and max of the axis unless they are
/// on the interval, because they overlap the neighboring title.
GetTitleWidgetFunction hideOffIntervalMinMax(GetTitleWidgetFunction getTitle) =>
    (value, meta) {
      final steps = value / meta.appliedInterval;
      final onInterval = (steps - steps.round()).abs() < 1e-6;
      return (value == meta.min || value == meta.max) && !onInterval
          ? const SizedBox.shrink()
          : getTitle(value, meta);
    };

LineTouchData touchCallback(void Function(double?) callback) => LineTouchData(
  handleBuiltInTouches: false,
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
