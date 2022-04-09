import 'package:flutter/material.dart';

class NeverPop extends StatelessWidget {
  final Widget child;
  const NeverPop({required this.child, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(child: child, onWillPop: () async => false);
  }
}
