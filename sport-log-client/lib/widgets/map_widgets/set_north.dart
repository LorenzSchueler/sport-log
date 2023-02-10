import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:sport_log/helpers/extensions/map_controller_extension.dart';
import 'package:sport_log/widgets/app_icons.dart';

class SetNorthButton extends StatelessWidget {
  const SetNorthButton({
    required this.mapController,
    super.key,
  });

  final MapboxMap mapController;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: null,
      onPressed: mapController.setNorth,
      child: const Icon(AppIcons.compass),
    );
  }
}
