import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:sport_log/helpers/extensions/location_data_extension.dart';
import 'package:sport_log/helpers/extensions/map_controller_extension.dart';
import 'package:sport_log/helpers/location_utils.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/app_icons.dart';

class CurrentLocationButton extends StatefulWidget {
  const CurrentLocationButton({
    required this.mapController,
    required this.centerLocation,
    super.key,
  });

  final MapboxMapController mapController;
  final bool centerLocation;

  @override
  State<CurrentLocationButton> createState() => _CurrentLocationButtonState();
}

class _CurrentLocationButtonState extends State<CurrentLocationButton> {
  List<Circle>? _currentLocationMarker = [];
  late final LocationUtils _locationUtils = LocationUtils(_onLocationUpdate);

  @override
  void dispose() {
    _locationUtils.stopLocationStream();
    if (_locationUtils.lastLatLng != null) {
      Settings.instance.lastGpsLatLng = _locationUtils.lastLatLng!;
    }
    super.dispose();
  }

  Future<void> _toggleCurrentLocation() async {
    if (_locationUtils.enabled) {
      _locationUtils.stopLocationStream();
      _currentLocationMarker =
          await widget.mapController.updateCurrentLocationMarker(
        _currentLocationMarker,
        null,
      );
    } else {
      await _locationUtils.startLocationStream();
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _onLocationUpdate(LocationData location) async {
    if (widget.centerLocation) {
      await widget.mapController.animateCenter(location.latLng);
    }
    _currentLocationMarker =
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
