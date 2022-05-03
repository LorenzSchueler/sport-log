import 'package:flutter/material.dart';

class DeactivatableTabBar extends StatelessWidget
    implements PreferredSizeWidget {
  final TabBar child;
  final bool disabled;

  const DeactivatableTabBar({
    required this.child,
    required this.disabled,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return disabled ? IgnorePointer(child: child) : child;
  }

  @override
  Size get preferredSize => child.preferredSize;
}
