import 'package:flutter/material.dart';
import 'package:sport_log/widgets/input_fields/edit_tile.dart';

class TextTile extends StatelessWidget {
  const TextTile({
    required this.child,
    this.leading,
    this.caption,
    this.onCancel,
    super.key,
  });

  final String? caption;
  final Widget child;
  final IconData? leading;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return EditTile(
      leading: leading,
      caption: caption,
      onCancel: onCancel,
      child: child,
    );
  }
}
