import 'package:flutter/material.dart';
import 'package:sport_log/routes.dart';

extension Nav on Navigator {
  static void newBase(BuildContext context, String route) {
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder<void>(
        pageBuilder: (context, animation1, animation2) =>
            Routes.get(route)(context),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
      (_) => false,
    );
  }
}
