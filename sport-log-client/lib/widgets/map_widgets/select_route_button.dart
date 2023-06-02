import 'package:flutter/material.dart' hide Route;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:sport_log/helpers/map_controller.dart';
import 'package:sport_log/helpers/pointer.dart';
import 'package:sport_log/models/cardio/route.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/picker/picker.dart';

class SelectRouteButton extends StatefulWidget {
  const SelectRouteButton({
    required this.mapController,
    super.key,
  });

  final MapController mapController;

  @override
  State<SelectRouteButton> createState() => _SelectRouteButtonState();
}

class _SelectRouteButtonState extends State<SelectRouteButton> {
  Route? _selectedRoute;
  final NullablePointer<PolylineAnnotation> _line =
      NullablePointer.nullPointer();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: null,
      onPressed: selectRoute,
      child: const Icon(AppIcons.route),
    );
  }

  Future<void> selectRoute() async {
    final route = await showRoutePicker(
      context: context,
      selectedRoute: _selectedRoute,
    );
    if (route == null) {
      return;
    } else if (route.id == _selectedRoute?.id) {
      _selectedRoute = null;
    } else {
      _selectedRoute = route;
    }
    await widget.mapController.updateRouteLine(_line, _selectedRoute?.track);
    await widget.mapController
        .setBoundsFromTracks(_selectedRoute?.track, null, padded: true);
  }
}
