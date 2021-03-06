import 'dart:math';

import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:provider/provider.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/location_data_extension.dart';
import 'package:sport_log/helpers/extensions/map_controller_extension.dart';
import 'package:sport_log/helpers/location_utils.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/map_widgets/map_scale.dart';
import 'package:sport_log/widgets/map_widgets/map_styles.dart';
import 'package:sport_log/widgets/map_widgets/set_north.dart';

class MapboxMapWrapper extends StatefulWidget {
  const MapboxMapWrapper({
    required this.showScale,
    required this.showMapStylesButton,
    required this.showCurrentLocationButton,
    required this.showSetNorthButton,
    this.buttonTopOffset = 0,
    this.scaleAtTop = false,
    this.styleString,
    this.initialCameraPosition,
    this.trackCameraPosition = false,
    this.onMapCreated,
    this.onStyleLoadedCallback,
    this.onMapClick,
    this.onMapLongClick,
    this.rotateGesturesEnabled = true,
    this.scrollGesturesEnabled = true,
    this.zoomGesturesEnabled = true,
    this.tiltGesturesEnabled = true,
    this.doubleClickZoomEnabled,
    super.key,
  });

  final bool showScale;
  final bool showMapStylesButton;
  final bool showCurrentLocationButton;
  final bool showSetNorthButton;
  final int buttonTopOffset;
  final bool scaleAtTop;

  /// defaults to [MapboxStyles.OUTDOORS]
  final String? styleString;

  /// defaults to [Settings.lastMapPosition]
  final CameraPosition? initialCameraPosition;

  /// automatically enabled when [showScale] is [true]
  final bool trackCameraPosition;
  final void Function(MapboxMapController)? onMapCreated;
  final void Function()? onStyleLoadedCallback;
  final void Function(Point<double>, LatLng)? onMapClick;
  final void Function(Point<double>, LatLng)? onMapLongClick;
  final bool rotateGesturesEnabled;
  final bool scrollGesturesEnabled;
  final bool zoomGesturesEnabled;
  final bool tiltGesturesEnabled;
  final bool? doubleClickZoomEnabled;

  @override
  State<MapboxMapWrapper> createState() => _MapboxMapWrapperState();
}

class _MapboxMapWrapperState extends State<MapboxMapWrapper> {
  MapboxMapController? _mapController;
  late String _mapStyle = widget.styleString ?? MapboxStyles.OUTDOORS;
  double _metersPerPixel = 1;
  List<Circle>? _currentLocationMarker = [];
  late final LocationUtils _locationUtils = LocationUtils(_onLocationUpdate);

  @override
  void dispose() {
    _locationUtils.stopLocationStream();
    _mapController?.removeListener(_mapControllerListener);
    final cameraPosition = _mapController?.cameraPosition;
    if (cameraPosition != null) {
      Settings.instance.lastMapPosition = cameraPosition;
    }
    if (_locationUtils.lastLatLng != null) {
      Settings.instance.lastGpsLatLng = _locationUtils.lastLatLng!;
    }
    super.dispose();
  }

  Future<void> _mapControllerListener() async {
    final latitude = _mapController!.cameraPosition!.target.latitude;

    final metersPerPixel =
        await _mapController!.getMetersPerPixelAtLatitude(latitude);
    setState(() => _metersPerPixel = metersPerPixel);
  }

  Future<void> _toggleCurrentLocation() async {
    if (_locationUtils.enabled) {
      _locationUtils.stopLocationStream();
      _currentLocationMarker =
          await _mapController?.updateCurrentLocationMarker(
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
    await _mapController?.animateCenter(location.latLng);
    _currentLocationMarker = await _mapController?.updateCurrentLocationMarker(
      _currentLocationMarker,
      location.latLng,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MapboxMap(
          accessToken: Config.instance.accessToken,
          styleString: _mapStyle,
          initialCameraPosition: widget.initialCameraPosition ??
              context.read<Settings>().lastMapPosition,
          trackCameraPosition: widget.showScale || widget.trackCameraPosition,
          onMapCreated: (MapboxMapController controller) {
            setState(() {
              _mapController = controller..addListener(_mapControllerListener);
            });
            widget.onMapCreated?.call(controller);
          },
          onStyleLoadedCallback: widget.onStyleLoadedCallback,
          onMapClick: widget.onMapClick,
          onMapLongClick: widget.onMapLongClick,
          rotateGesturesEnabled: widget.rotateGesturesEnabled,
          scrollGesturesEnabled: widget.scrollGesturesEnabled,
          zoomGesturesEnabled: widget.zoomGesturesEnabled,
          tiltGesturesEnabled: widget.tiltGesturesEnabled,
          doubleClickZoomEnabled: widget.doubleClickZoomEnabled,
          dragEnabled: false,
        ),
        if (widget.showScale)
          widget.scaleAtTop
              ? Positioned(
                  top: 10,
                  left: 10,
                  child: MapScale(metersPerPixel: _metersPerPixel),
                )
              : Positioned(
                  bottom: 10,
                  right: 10,
                  child: MapScale(metersPerPixel: _metersPerPixel),
                ),
        if (_mapController != null)
          Positioned(
            top: widget.buttonTopOffset + 15,
            right: 15,
            child: Column(
              children: [
                if (widget.showMapStylesButton) ...[
                  MapStylesButton(
                    mapController: _mapController!,
                    onStyleChange: (style) => setState(() => _mapStyle = style),
                  ),
                  Defaults.sizedBox.vertical.normal,
                ],
                if (widget.showCurrentLocationButton) ...[
                  FloatingActionButton.small(
                    heroTag: null,
                    onPressed: _toggleCurrentLocation,
                    child: Icon(
                      _locationUtils.enabled
                          ? AppIcons.myLocation
                          : AppIcons.myLocationDisabled,
                    ),
                  ),
                  Defaults.sizedBox.vertical.normal,
                ],
                if (widget.showSetNorthButton)
                  SetNorthButton(mapController: _mapController!),
              ],
            ),
          ),
      ],
    );
  }
}
