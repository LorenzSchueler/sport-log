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

/// Hides the titles of fractional values.
GetTitleWidgetFunction hideFractional(GetTitleWidgetFunction getTitle) =>
    (value, meta) => (value - value.round()).abs() < 1e-6
    ? getTitle(value, meta)
    : const SizedBox.shrink();

const _verticalAxisTitleSpace = 8.0;

Size _titleSize(BuildContext context, String title) {
  final painter = TextPainter(
    text: TextSpan(text: title, style: DefaultTextStyle.of(context).style),
    textScaler: MediaQuery.textScalerOf(context),
    textDirection: TextDirection.ltr,
  )..layout();
  final size = painter.size;
  painter.dispose();
  return size;
}

/// Reserved size of a vertical axis that fits [title].
double verticalAxisReservedSize(BuildContext context, String title) =>
    _titleSize(context, title).width.ceilToDouble() + _verticalAxisTitleSpace;

/// Reserved size of a horizontal axis that fits one line of titles.
double horizontalAxisReservedSize(BuildContext context) =>
    _titleSize(context, "0").height.ceilToDouble();

/// Shifts the titles at the ends of the axis inwards so they stay inside the
/// chart. Titles of a horizontal axis touch the chart.
GetTitleWidgetFunction fitInside(GetTitleWidgetFunction getTitle) =>
    (value, meta) => SideTitleWidget(
      meta: meta,
      space: switch (meta.axisSide) {
        AxisSide.left || AxisSide.right => _verticalAxisTitleSpace,
        AxisSide.top || AxisSide.bottom => 0,
      },
      fitInside: SideTitleFitInsideData.fromTitleMeta(
        meta,
        distanceFromEdge: 0,
      ),
      child: getTitle(value, meta),
    );

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
