import 'package:flutter/material.dart';
import 'package:sport_log/routes.dart';

extension NavigatorNewBase on NavigatorState {
  Future<void> newBase(String route) => pushAndRemoveUntil(
    PageRouteBuilder<void>(
      settings: RouteSettings(name: route),
      pageBuilder: (context, animation1, animation2) =>
          Routes.get(route)(context),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    ),
    (_) => false,
  );
}
