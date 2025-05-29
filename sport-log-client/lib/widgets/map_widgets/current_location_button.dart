import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:sport_log/helpers/gps_position.dart';
import 'package:sport_log/helpers/location_utils.dart';
import 'package:sport_log/helpers/map_controller.dart';
import 'package:sport_log/helpers/pointer.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/provider_consumer.dart';

class CurrentLocationButton extends StatelessWidget {
  const CurrentLocationButton({
    required this.mapController,
    required this.centerLocation,
    required this.locationUtils,
    required this.currentLocationMarker,
    super.key,
  });

  final MapController mapController;
  final LocationUtils locationUtils;
  final Pointer<bool> centerLocation;
  final NullablePointer<List<CircleAnnotation>> currentLocationMarker;

  Future<void> _toggleCurrentLocation() async {
    if (locationUtils.enabled) {
      if (locationUtils.inBackground) {
        await locationUtils.stopLocationStream();
        await mapController.updateCurrentLocationMarker(
          currentLocationMarker,
          null,
          false,
        );
      } else {
        await locationUtils.stopLocationStream();
        await locationUtils.startLocationStream(
          onLocationUpdate: _onLocationUpdate,
          inBackground: true,
        );
      }
    } else {
      await locationUtils.startLocationStream(
        onLocationUpdate: _onLocationUpdate,
        inBackground: false,
      );
    }
  }

  Future<void> _onLocationUpdate(GpsPosition location) async {
    if (centerLocation.object) {
      await mapController.animateCenter(location.latLng);
    }
    await mapController.updateCurrentLocationMarker(
      currentLocationMarker,
      location.latLng,
      location.isGps,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProviderConsumer.value(
      value: locationUtils,
      builder: (context, locationUtils, _) => FloatingActionButton.small(
        heroTag: null,
        onPressed: _toggleCurrentLocation,
        tooltip: "GPS Location (off - foreground - background)",
        child: Icon(
          locationUtils.enabled
              ? locationUtils.inBackground
                    ? AppIcons.myLocationBackground
                    : AppIcons.myLocationForeground
              : AppIcons.myLocationOff,
        ),
      ),
    );
  }
}
