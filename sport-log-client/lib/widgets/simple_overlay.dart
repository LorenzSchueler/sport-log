import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SimpleOverlay extends StatelessWidget {
  const SimpleOverlay({
    Key? key,
    required this.child,
    required this.overlay,
    required this.showOverlay,
    required this.hideOverlay,
  }) : super(key: key);

  final Widget child;
  final Widget overlay;
  final bool showOverlay;
  final void Function() hideOverlay;

  @override
  Widget build(BuildContext context) {
    const duration = Duration(milliseconds: 300);
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        AnimatedSwitcher(
          duration: duration,
          child: showOverlay
              ? GestureDetector(
                  child: Container(color: Colors.black.withAlpha(100)),
                  onTap: () => hideOverlay(),
                )
              : null,
        ),
        AnimatedSwitcher(
          duration: duration,
          child: showOverlay ? overlay : null,
        ),
      ],
    );
  }
}
