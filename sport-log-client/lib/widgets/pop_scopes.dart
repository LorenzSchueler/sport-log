import 'package:flutter/material.dart';
import 'package:sport_log/widgets/dialogs/approve_dialog.dart';

class NeverPop extends StatelessWidget {
  const NeverPop({required this.child, Key? key}) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(child: child, onWillPop: () async => false);
  }
}

class DiscardWarningOnPop extends StatelessWidget {
  const DiscardWarningOnPop({required this.child, Key? key}) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: child,
      onWillPop: () => showDiscardWarningDialog(context),
    );
  }
}
