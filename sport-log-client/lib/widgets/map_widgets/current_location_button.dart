import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:sport_log/helpers/extensions/location_data_extension.dart';
import 'package:sport_log/helpers/location_utils.dart';
import 'package:sport_log/helpers/map_controller.dart';
import 'package:sport_log/helpers/pointer.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/provider_consumer.dart';

class CurrentLocationButton extends StatelessWidget {
  CurrentLocationButton({
    required this.mapController,
    required this.centerLocation,
    super.key,
  });

  final MapController mapController;
  final bool centerLocation;

  final NullablePointer<List<CircleAnnotation>> _currentLocationMarker =
      NullablePointer.nullPointer();

  Future<void> _toggleCurrentLocation(LocationUtils locationUtils) async {
    if (locationUtils.enabled) {
      await locationUtils.stopLocationStream();
      await mapController.updateCurrentLocationMarker(
        _currentLocationMarker,
        null,
        false,
      );
    } else {
      await locationUtils.startLocationStream(_onLocationUpdate);
    }
  }

  Future<void> _onLocationUpdate(LocationData location) async {
    if (centerLocation) {
      await mapController.animateCenter(location.latLng);
    }
    await mapController.updateCurrentLocationMarker(
      _currentLocationMarker,
      location.latLng,
      location.isGps,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProviderConsumer(
      create: (_) => LocationUtils(),
      builder: (context, locationUtils, _) => FloatingActionButton.small(
        heroTag: null,
        onPressed: () => _toggleCurrentLocation(locationUtils),
        child: Icon(
          locationUtils.enabled
              ? AppIcons.myLocation
              : AppIcons.myLocationDisabled,
        ),
      ),
    );
  }
}
