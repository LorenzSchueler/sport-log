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
  _SpinningSyncState createState() => _SpinningSyncState();
}

class _SpinningSyncState extends State<SpinningSync>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _duration = Duration(milliseconds: 1000);

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: _duration,
    )..addStatusListener((status) {
        switch (status) {
          case AnimationStatus.dismissed:
            break;
          case AnimationStatus.forward:
            // TODO: Handle this case.
            break;
          case AnimationStatus.reverse:
            // TODO: Handle this case.
            break;
          case AnimationStatus.completed:
            if (widget.isSpinning) {
              _controller.forward(from: 0);
            }
            break;
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
        icon: const Icon(AppIcons.syncClockwise),
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
