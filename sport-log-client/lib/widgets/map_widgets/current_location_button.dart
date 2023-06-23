import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:sport_log/helpers/gps_position.dart';
import 'package:sport_log/helpers/location_utils.dart';
import 'package:sport_log/helpers/map_controller.dart';
import 'package:sport_log/helpers/pointer.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/provider_consumer.dart';

// Needs to be stateful because otherwise object holding _centerLocation and _currentLocationMarker will change.
// Therefor _centerLocation and _currentLocationMarker of the old object (which is referenced in the callback) will not be updated and are not longer accessible.
// This results in centerLocation not being applied and location markers not being removed.
class CurrentLocationButton extends StatefulWidget {
  const CurrentLocationButton({
    required this.mapController,
    required this.centerLocation,
    super.key,
  });

  final MapController mapController;
  final bool centerLocation;

  @override
  State<CurrentLocationButton> createState() => _CurrentLocationButtonState();
}

class _CurrentLocationButtonState extends State<CurrentLocationButton> {
  late bool _centerLocation = widget.centerLocation;
  final NullablePointer<List<CircleAnnotation>> _currentLocationMarker =
      NullablePointer.nullPointer();
  final LocationUtils _locationUtils = LocationUtils();

  @override
  void didUpdateWidget(CurrentLocationButton oldWidget) {
    _centerLocation = widget.centerLocation;
    if (_centerLocation) {
      final lastLocation = _locationUtils.lastLocation;
      if (lastLocation != null) {
        _onLocationUpdate(lastLocation);
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  Future<void> _toggleCurrentLocation() async {
    if (_locationUtils.enabled) {
      await _locationUtils.stopLocationStream();
      await widget.mapController.updateCurrentLocationMarker(
        _currentLocationMarker,
        null,
        false,
      );
    } else {
      await _locationUtils.startLocationStream(_onLocationUpdate);
    }
  }

  Future<void> _onLocationUpdate(GpsPosition location) async {
    if (_centerLocation) {
      await widget.mapController.animateCenter(location.latLng);
    }
    await widget.mapController.updateCurrentLocationMarker(
      _currentLocationMarker,
      location.latLng,
      location.isGps,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProviderConsumer.value(
      value: _locationUtils,
      builder: (context, locationUtils, _) => FloatingActionButton.small(
        heroTag: null,
        onPressed: _toggleCurrentLocation,
        child: Icon(
          locationUtils.enabled
              ? AppIcons.myLocation
              : AppIcons.myLocationDisabled,
        ),
      ),
    );
  }
}
