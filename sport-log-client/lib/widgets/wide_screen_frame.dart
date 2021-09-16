
import 'package:flutter/material.dart';

class WideScreenFrame extends StatelessWidget {
  const WideScreenFrame({
    Key? key,
    this.child,
  }) : super(key: key);

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.topCenter,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 800,
        ),
        child: child,
      ),
    );
  }
}