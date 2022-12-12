import 'package:flutter/material.dart';
import 'package:sport_log/widgets/app_icons.dart';

class ToggleCenterLocationButton extends StatefulWidget {
  const ToggleCenterLocationButton({
    required this.onToggle,
    super.key,
  });

  final void Function(bool isCentered)? onToggle;

  @override
  State<ToggleCenterLocationButton> createState() =>
      _ToggleCenterLocationButtonState();
}

class _ToggleCenterLocationButtonState
    extends State<ToggleCenterLocationButton> {
  bool _isCentered = true;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: null,
      onPressed: () {
        setState(() => _isCentered = !_isCentered);
        widget.onToggle?.call(_isCentered);
      },
      child: Icon(_isCentered ? AppIcons.centerFocus : AppIcons.centerFocusOff),
    );
  }
}
