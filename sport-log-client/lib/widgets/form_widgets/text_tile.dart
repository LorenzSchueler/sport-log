import 'package:flutter/material.dart';
import 'package:sport_log/widgets/form_widgets/edit_tile.dart';

class TextTile extends StatelessWidget {
  const TextTile({
    Key? key,
    required this.child,
    this.leading,
    this.caption,
  }) : super(key: key);

  final String? caption;
  final Widget child;
  final IconData? leading;

  @override
  Widget build(BuildContext context) {
    return EditTile(child: child, leading: leading, caption: caption);
  }
}