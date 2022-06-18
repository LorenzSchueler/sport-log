import 'dart:async';

import 'package:flutter/material.dart';

class RepeatIconButton extends StatefulWidget {
  const RepeatIconButton({
    required this.icon,
    required this.onClick,
    this.color,
    super.key,
  });

  final Icon icon;
  final VoidCallback? onClick;
  final Color? color;

  @override
  State<RepeatIconButton> createState() => _RepeatIconButtonState();
}

class _RepeatIconButtonState extends State<RepeatIconButton> {
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: widget.icon,
        color: widget.color,
        onPressed: widget.onClick,
      ),
      onLongPress: () => _timer = Timer.periodic(
        const Duration(milliseconds: 80),
        (_) => widget.onClick?.call(),
      ),
      onLongPressEnd: (_) => _timer?.cancel(),
    );
  }
}
