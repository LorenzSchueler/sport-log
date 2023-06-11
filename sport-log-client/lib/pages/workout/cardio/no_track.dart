import 'package:flutter/material.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/widgets/app_icons.dart';

class NoTrackPlaceholder extends StatelessWidget {
  const NoTrackPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          AppIcons.route,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        Defaults.sizedBox.horizontal.normal,
        const Text("No Track Available"),
      ],
    );
  }
}
