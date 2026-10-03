import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:sport_log/theme.dart';

class RepeatIconButton extends StatefulWidget {
  const RepeatIconButton({
    required this.icon,
    required this.onClick,
    this.materialTapTargetSize = MaterialTapTargetSize.padded,
    this.color,
    this.tonal = false,
    super.key,
  });

  final Icon icon;
  final VoidCallback? onClick;
  final MaterialTapTargetSize materialTapTargetSize;
  final Color? color;

  /// Uses [AppTheme.tonalButtonStyle] like the tonal filled buttons.
  final bool tonal;

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
        style: ButtonStyle(tapTargetSize: widget.materialTapTargetSize)
            .merge(widget.tonal ? AppTheme.tonalButtonStyle() : null),
      ),
      onLongPress: () => _timer = Timer.periodic(
        const Duration(milliseconds: 80),
        (_) => widget.onClick?.call(),
      ),
      onLongPressEnd: (_) => _timer?.cancel(),
    );
  }
}
