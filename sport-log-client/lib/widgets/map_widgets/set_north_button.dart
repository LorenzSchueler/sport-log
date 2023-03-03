import 'package:flutter/material.dart';
import 'package:sport_log/helpers/map_controller.dart';
import 'package:sport_log/widgets/app_icons.dart';

class SetNorthButton extends StatelessWidget {
  const SetNorthButton({
    required this.mapController,
    super.key,
  });

  final MapController mapController;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: null,
      onPressed: mapController.animateNorth,
      child: const Icon(AppIcons.compass),
    );
  }
}
