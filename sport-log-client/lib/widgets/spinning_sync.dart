import 'package:flutter/material.dart';
import 'package:sport_log/widgets/app_icons.dart';

class SpinningSync extends StatefulWidget {
  const SpinningSync({
    Key? key,
    required this.isSpinning,
    required this.onPressed,
    this.color,
  }) : super(key: key);

  final bool isSpinning;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  State<SpinningSync> createState() => _SpinningSyncState();
}

class _SpinningSyncState extends State<SpinningSync>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          // repeat animation
          if (widget.isSpinning) {
            _controller.forward(from: 0);
          }
        }
      });

    if (widget.isSpinning) {
      _controller.forward();
    }
    super.initState();
  }

  @override
  void didUpdateWidget(SpinningSync oldWidget) {
    if (!oldWidget.isSpinning && widget.isSpinning) {
      _controller.forward(from: 0);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: IconButton(
        onPressed: widget.onPressed,
        icon: Transform.scale(
          scaleX: -1,
          child: const Icon(AppIcons.sync),
        ),
        color: widget.color,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
