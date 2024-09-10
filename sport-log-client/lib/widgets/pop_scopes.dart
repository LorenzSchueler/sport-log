import 'package:flutter/material.dart';
import 'package:sport_log/widgets/dialogs/dialogs.dart';

class NeverPop extends StatelessWidget {
  const NeverPop({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(canPop: false, child: child);
  }
}

class DiscardWarningOnPop extends StatelessWidget {
  const DiscardWarningOnPop({required this.child, this.onDiscard, super.key});

  final Widget child;
  final void Function()? onDiscard;

  Future<void> onPopInvoked(BuildContext context, bool didPop) async {
    if (didPop) {
      return;
    }
    final discard = await showDiscardWarningDialog(context);
    if (discard) {
      onDiscard?.call();
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => onPopInvoked(context, didPop),
      child: child,
    );
  }
}
