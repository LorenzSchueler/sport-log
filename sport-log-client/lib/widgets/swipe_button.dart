import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:sport_log/widgets/app_icons.dart';

class SwipeButton extends StatefulWidget {
  SwipeButton({
    required this.thumbLabel,
    required this.onSwipe,
    this.height = 40,
    this.color,
    this.backgroundColor,
    this.acceptSwipe = 0.9,
    super.key,
  }) : borderRadius = BorderRadius.circular(height / 2);

  final String thumbLabel;
  final double height;
  final void Function() onSwipe;
  final BorderRadius borderRadius;
  final Color? color;
  final Color? backgroundColor;
  final double acceptSwipe;

  @override
  SwipeButtonState createState() => SwipeButtonState();
}

class SwipeButtonState extends State<SwipeButton>
    with SingleTickerProviderStateMixin {
  final GlobalKey _buttonKey = GlobalKey();
  final GlobalKey _thumbKey = GlobalKey();

  late AnimationController _controller;

  RenderBox? get _thumb =>
      _thumbKey.currentContext?.findRenderObject() as RenderBox?;
  RenderBox? get _button =>
      _buttonKey.currentContext?.findRenderObject() as RenderBox?;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: AnimatedBuilder(
        key: _buttonKey,
        animation: _controller,
        builder: (context, child) => Stack(
          children: [
            Container(
              height: widget.height,
              decoration: BoxDecoration(
                color: widget.backgroundColor ??
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: widget.borderRadius,
              ),
            ),
            Align(
              alignment: Alignment((_controller.value * 2.0) - 1.0, 0),
              child: GestureDetector(
                onHorizontalDragUpdate: _onDragUpdate,
                onHorizontalDragEnd: _onDragEnd,
                child: Container(
                  key: _thumbKey,
                  height: widget.height,
                  padding: EdgeInsets.only(
                    left: widget.height / 3,
                    right: widget.height / 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSwipeComplete
                        ? Theme.of(context).colorScheme.errorContainer
                        : widget.color ?? Theme.of(context).colorScheme.primary,
                    borderRadius: widget.borderRadius,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.thumbLabel,
                        style: Theme.of(context)
                            .filledButtonTheme
                            .style!
                            .textStyle!
                            .resolve({WidgetState.focused})!.copyWith(
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(AppIcons.arrowRight, color: Colors.black),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final width = _button!.size.width;
    final thumbWidth = _thumb!.size.width;
    final halfThumbWidth = thumbWidth / 2;
    final pos = _button!.globalToLocal(details.globalPosition).dx;
    final value = pos - halfThumbWidth; // keep thumb centered at touch point
    final extent = width - thumbWidth;
    _controller.value = value.clamp(0.0, extent) / extent;
  }

  void _onDragEnd(DragEndDetails _) {
    if (isSwipeComplete) {
      _controller.value = 0;
      widget.onSwipe();
    } else {
      _controller.animateWith(
        _MoveBackSimulation(-2, _controller.value, 0, -2),
      );
    }
  }

  bool get isSwipeComplete =>
      _controller.value >= widget.acceptSwipe.clamp(-1, 1);
}

class _MoveBackSimulation extends GravitySimulation {
  _MoveBackSimulation(
    super.acceleration,
    super.distance,
    super.endDistance,
    super.velocity,
  );

  @override
  double x(double time) => super.x(time).clamp(0.0, 1.0);

  @override
  bool isDone(double time) => x(time) <= 0 || x(time) >= 1;
}
