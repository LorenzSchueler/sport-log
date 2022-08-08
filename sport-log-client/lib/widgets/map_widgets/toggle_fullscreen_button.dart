import 'package:flutter/material.dart';
import 'package:sport_log/helpers/extensions/map_controller_extension.dart';
import 'package:sport_log/widgets/app_icons.dart';

class ToggleFullscreenButton extends StatefulWidget {
  const ToggleFullscreenButton({
    required this.onToggle,
    super.key,
  });

  final void Function(bool fullscreen)? onToggle;

  @override
  State<ToggleFullscreenButton> createState() => _ToggleFullscreenButtonState();
}

class _ToggleFullscreenButtonState extends State<ToggleFullscreenButton> {
  bool _fullscreen = false;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: null,
      onPressed: () {
        setState(() => _fullscreen = !_fullscreen);
        widget.onToggle?.call(_fullscreen);
      },
      child: Icon(_fullscreen ? AppIcons.closeFullScreen : AppIcons.fullScreen),
    );
  }
}
