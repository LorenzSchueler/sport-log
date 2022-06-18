import 'package:flutter/material.dart';

class DeactivatableTabBar extends StatelessWidget
    implements PreferredSizeWidget {
  const DeactivatableTabBar({
    required this.child,
    required this.disabled,
    super.key,
  });

  final TabBar child;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return disabled ? IgnorePointer(child: child) : child;
  }

  @override
  Size get preferredSize => child.preferredSize;
}
