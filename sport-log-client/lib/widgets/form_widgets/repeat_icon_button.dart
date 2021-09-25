import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RepeatIconButton extends StatefulWidget {
  RepeatIconButton({
    Key? key,
    required this.icon,
    VoidCallback? onClick,
    VoidCallback? onRepeat,
    VoidCallback? onRepeatEnd,
    this.color,
    this.enabled = true,
  })  : onClick = onClick ?? defaultCallback,
        onRepeat = onRepeat ?? defaultCallback,
        onRepeatEnd = onRepeatEnd ?? defaultCallback,
        super(key: key);

  static final defaultCallback = (() {});

  final Icon icon;
  final VoidCallback onClick;
  final VoidCallback onRepeat;
  final VoidCallback onRepeatEnd;
  final Color? color;
  final bool enabled;

  @override
  State<RepeatIconButton> createState() => _RepeatIconButtonState();
}

class _RepeatIconButtonState extends State<RepeatIconButton> {
  Timer? _timer;

  @override
  void didUpdateWidget(covariant RepeatIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) {
      _timer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: IconButton(
        icon: widget.icon,
        onPressed: widget.enabled
            ? () {
                widget.onClick();
              }
            : null,
        color: widget.color,
      ),
      onLongPress: widget.enabled
          ? () {
              _timer =
                  Timer.periodic(const Duration(milliseconds: 80), (timer) {
                widget.onRepeat();
              });
            }
          : null,
      onLongPressEnd: (_) {
        _timer?.cancel();
        widget.onRepeatEnd();
      },
    );
  }
}
