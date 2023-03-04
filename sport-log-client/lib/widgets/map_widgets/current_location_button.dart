import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Settings;
import 'package:sport_log/helpers/extensions/location_data_extension.dart';
import 'package:sport_log/helpers/location_utils.dart';
import 'package:sport_log/helpers/map_controller.dart';
import 'package:sport_log/helpers/pointer.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/app_icons.dart';

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
  final NullablePointer<List<CircleAnnotation>> _currentLocationMarker =
      NullablePointer.nullPointer();
  final LocationUtils _locationUtils = LocationUtils();

  @override
  void dispose() {
    final lastGpsPosition = _locationUtils.lastLatLng;
    if (lastGpsPosition != null) {
      Settings.instance.lastGpsLatLng = lastGpsPosition;
    }
    _locationUtils.stopLocationStream();
    super.dispose();
  }

  Future<void> _toggleCurrentLocation() async {
    if (_locationUtils.enabled) {
      await _locationUtils.stopLocationStream();
      await widget.mapController.updateCurrentLocationMarker(
        _currentLocationMarker,
        null,
      );
    } else {
      await _locationUtils.startLocationStream(_onLocationUpdate);
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _onLocationUpdate(LocationData location) async {
    if (widget.centerLocation) {
      await widget.mapController.animateCenter(location.latLng);
    }
    await widget.mapController.updateCurrentLocationMarker(
      _currentLocationMarker,
      location.latLng,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: null,
      onPressed: _toggleCurrentLocation,
      child: Icon(
        _locationUtils.enabled
            ? AppIcons.myLocation
            : AppIcons.myLocationDisabled,
      ),
    );
  }
}
