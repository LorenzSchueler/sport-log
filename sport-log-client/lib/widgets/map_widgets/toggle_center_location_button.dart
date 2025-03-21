import 'package:flutter/material.dart';
import 'package:sport_log/widgets/app_icons.dart';

class ToggleCenterLocationButton extends StatelessWidget {
  const ToggleCenterLocationButton({
    required this.centerLocation,
    required this.onToggle,
    super.key,
  });

  final bool centerLocation;
  final void Function() onToggle;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: null,
      onPressed: onToggle,
      child: Icon(
        centerLocation ? AppIcons.centerFocus : AppIcons.centerFocusOff,
      ),
    );
  }
}
