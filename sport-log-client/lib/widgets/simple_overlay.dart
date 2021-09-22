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
    return WillPopScope(
      onWillPop: () async {
        if (showOverlay) {
          hideOverlay();
          return false;
        }
        return true;
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          child,
          Visibility(
            child: GestureDetector(
              child: Container(color: Colors.black.withAlpha(100)),
              onTap: () => hideOverlay(),
            ),
            visible: showOverlay,
          ),
          Visibility(
            child: overlay,
            visible: showOverlay,
          ),
        ],
      ),
    );
  }
}
