import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class _ItemScrollPhysics extends ScrollPhysics {
  const _ItemScrollPhysics({
    super.parent,
    required this.itemHeight,
    required this.maxItems,
  }) : assert(itemHeight > 0);

  final double itemHeight;
  final int maxItems;

  @override
  _ItemScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _ItemScrollPhysics(
      parent: buildParent(ancestor),
      itemHeight: itemHeight,
      maxItems: maxItems,
    );
  }

  double _getEndPixels(double start, double velocity) {
    final item = start / itemHeight;
    final itemsStep = velocity / 10000 * maxItems;
    return (item + itemsStep).roundToDouble() * itemHeight;
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final start = position.pixels;
    final end = _getEndPixels(start, velocity);
    return start != end
        ? ScrollSpringSimulation(spring, start, end, velocity)
        : null;
  }

  @override
  bool get allowImplicitScrolling => false;
}

class TimeSpinner extends StatefulWidget {
  const TimeSpinner({
    required this.onTimeChange,
    this.time,
    this.is24HourMode = true,
    this.isShowSeconds = true,
    this.selectedTextStyle = const TextStyle(fontSize: 32, color: Colors.black),
    this.normalTextStyle = const TextStyle(fontSize: 32, color: Colors.grey),
    double height = 180,
    double width = 250,
    this.alignment = Alignment.center,
    super.key,
  }) : itemHeight = height / 3,
       itemWidth =
           width / (2 + (is24HourMode ? 0 : 1) + (isShowSeconds ? 1 : 0));

  final void Function(DateTime) onTimeChange;
  final DateTime? time;
  final bool is24HourMode;
  final bool isShowSeconds;
  final TextStyle selectedTextStyle;
  final TextStyle normalTextStyle;
  final double itemHeight;
  final double itemWidth;
  final Alignment alignment;

  @override
  State<TimeSpinner> createState() => _TimeSpinnerState();
}

class _TimeSpinnerState extends State<TimeSpinner> {
  late DateTime initTime = widget.time ?? DateTime.now();

  // +max to get into max <= x < 2*max
  late int selectedHour = initTime.hour % maxHour + maxHour;
  late int selectedMinute = initTime.minute + 60;
  late int selectedSecond = initTime.second + 60;
  // 1 = AM; 2 = PM, 0,3 = placeholder
  late int selectedAmPm = initTime.hour < 12 ? 1 : 2;

  // -1 to put marked number in center not top
  late final ScrollController hourController = ScrollController(
    initialScrollOffset: (selectedHour - 1) * widget.itemHeight,
  );
  late final ScrollController minuteController = ScrollController(
    initialScrollOffset: (selectedMinute - 1) * widget.itemHeight,
  );
  late final ScrollController secondController = ScrollController(
    initialScrollOffset: (selectedSecond - 1) * widget.itemHeight,
  );
  late final ScrollController amPmController = ScrollController(
    initialScrollOffset: (selectedAmPm - 1) * widget.itemHeight,
  );

  int get maxHour => widget.is24HourMode ? 24 : 12;

  DateTime get currentTime {
    final is12hPm = !widget.is24HourMode && selectedAmPm == 2;
    final hour = selectedHour % maxHour + (is12hPm ? 12 : 0);
    final minute = selectedMinute % 60;
    final second = selectedSecond % 60;
    return DateTime(
      initTime.year,
      initTime.month,
      initTime.day,
      hour,
      minute,
      second,
    );
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.onTimeChange(currentTime),
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Spinner(
          controller: hourController,
          max: maxHour,
          selected: selectedHour,
          onUpdate: (selected) {
            setState(() => selectedHour = selected);
            widget.onTimeChange(currentTime);
          },
          isHour: true,
          is24HourMode: widget.is24HourMode,
          itemHeight: widget.itemHeight,
          itemWidth: widget.itemWidth,
          alignment: widget.alignment,
          selectedTextStyle: widget.selectedTextStyle,
          normalTextStyle: widget.normalTextStyle,
        ),
        _Spinner(
          controller: minuteController,
          max: 60,
          selected: selectedMinute,
          onUpdate: (selected) {
            setState(() => selectedMinute = selected);
            widget.onTimeChange(currentTime);
          },
          isHour: false,
          is24HourMode: widget.is24HourMode,
          itemHeight: widget.itemHeight,
          itemWidth: widget.itemWidth,
          alignment: widget.alignment,
          selectedTextStyle: widget.selectedTextStyle,
          normalTextStyle: widget.normalTextStyle,
        ),
        if (widget.isShowSeconds)
          _Spinner(
            controller: secondController,
            max: 60,
            selected: selectedSecond,
            onUpdate: (selected) {
              setState(() => selectedSecond = selected);
              widget.onTimeChange(currentTime);
            },
            isHour: false,
            is24HourMode: widget.is24HourMode,
            itemHeight: widget.itemHeight,
            itemWidth: widget.itemWidth,
            alignment: widget.alignment,
            selectedTextStyle: widget.selectedTextStyle,
            normalTextStyle: widget.normalTextStyle,
          ),
        if (!widget.is24HourMode)
          _AmPmSpinner(
            controller: amPmController,
            selected: selectedAmPm,
            onUpdate: (selected) {
              setState(() => selectedAmPm = selected);
              widget.onTimeChange(currentTime);
            },
            itemHeight: widget.itemHeight,
            itemWidth: widget.itemWidth,
            alignment: widget.alignment,
            selectedTextStyle: widget.selectedTextStyle,
            normalTextStyle: widget.normalTextStyle,
          ),
      ],
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner({
    required this.controller,
    required this.max,
    required this.selected,
    required this.onUpdate,
    required this.isHour,
    required this.is24HourMode,
    required this.itemHeight,
    required this.itemWidth,
    required this.alignment,
    required this.selectedTextStyle,
    required this.normalTextStyle,
  });

  final ScrollController controller;
  final int max;
  final int selected;
  final void Function(int) onUpdate;
  final bool isHour;
  final bool is24HourMode;
  final double itemHeight;
  final double itemWidth;
  final Alignment alignment;
  final TextStyle selectedTextStyle;
  final TextStyle normalTextStyle;

  bool _onScrollNotification(ScrollNotification scrollNotification) {
    if (scrollNotification is UserScrollNotification &&
        scrollNotification.direction == ScrollDirection.idle) {
      if (selected < max) {
        onUpdate(selected + max);
        Future.delayed(
          Duration.zero,
          () => controller.jumpTo(controller.offset + max * itemHeight),
        );
      } else if (selected >= max * 2) {
        onUpdate(selected - max);
        Future.delayed(
          Duration.zero,
          () => controller.jumpTo(controller.offset - max * itemHeight),
        );
      }
    } else if (scrollNotification is ScrollUpdateNotification) {
      // +1 so that selected item is the one in center not top
      final newSelected = (controller.offset / itemHeight).round() + 1;
      onUpdate(newSelected);
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: itemWidth,
      height: itemHeight * 3,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: ListView.builder(
          itemBuilder: (_, index) {
            var text = (index % max).toString();
            if (!is24HourMode && isHour && text == '0') {
              text = '12';
            }
            text = text.padLeft(2, '0');
            return Container(
              height: itemHeight,
              width: itemWidth,
              alignment: alignment,
              child: Text(
                text,
                style: selected == index ? selectedTextStyle : normalTextStyle,
              ),
            );
          },
          itemCount: max * 3,
          controller: controller,
          physics: _ItemScrollPhysics(itemHeight: itemHeight, maxItems: max),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _AmPmSpinner extends StatelessWidget {
  const _AmPmSpinner({
    required this.controller,
    required this.selected,
    required this.onUpdate,
    required this.itemHeight,
    required this.itemWidth,
    required this.alignment,
    required this.selectedTextStyle,
    required this.normalTextStyle,
  });

  final ScrollController controller;
  final int selected;
  final void Function(int) onUpdate;
  final double itemHeight;
  final double itemWidth;
  final Alignment alignment;
  final TextStyle selectedTextStyle;
  final TextStyle normalTextStyle;

  bool _onAmPmScrollNotification(ScrollNotification scrollNotification) {
    if (scrollNotification is ScrollUpdateNotification) {
      // +1 so that selected item is the one in center not top
      final newSelected = (controller.offset / itemHeight).round() + 1;
      onUpdate(newSelected);
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: itemWidth,
      height: itemHeight * 3,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onAmPmScrollNotification,
        child: ListView.builder(
          itemBuilder: (_, index) {
            return Container(
              height: itemHeight,
              alignment: Alignment.center,
              child: Text(
                index == 1
                    ? "AM"
                    : index == 2
                    ? "PM"
                    : "",
                style: selected == index ? selectedTextStyle : normalTextStyle,
              ),
            );
          },
          itemCount: 4,
          controller: controller,
          physics: _ItemScrollPhysics(itemHeight: itemHeight, maxItems: 2),
        ),
      ),
    );
  }
}
