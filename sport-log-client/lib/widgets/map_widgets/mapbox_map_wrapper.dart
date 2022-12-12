import 'dart:math';

import 'package:flutter/material.dart' hide Route;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:provider/provider.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/map_widgets/current_location_button.dart';
import 'package:sport_log/widgets/map_widgets/map_scale.dart';
import 'package:sport_log/widgets/map_widgets/map_styles.dart';
import 'package:sport_log/widgets/map_widgets/select_route.dart';
import 'package:sport_log/widgets/map_widgets/set_north.dart';
import 'package:sport_log/widgets/map_widgets/toggle_center_location_button.dart';
import 'package:sport_log/widgets/map_widgets/toggle_fullscreen_button.dart';

class MapboxMapWrapper extends StatefulWidget {
  const MapboxMapWrapper({
    required this.showScale,
    required this.showFullscreenButton,
    required this.showMapStylesButton,
    required this.showSelectRouteButton,
    required this.showSetNorthButton,
    required this.showCurrentLocationButton,
    required this.showCenterLocationButton,
    this.showOverlays = true,
    this.buttonTopOffset = 0,
    this.scaleAtTop = false,
    this.onFullscreenToggle,
    this.onCenterLocationToggle,
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
  final bool showFullscreenButton;
  final bool showMapStylesButton;
  final bool showSelectRouteButton;
  final bool showSetNorthButton;
  final bool showCurrentLocationButton;
  final bool showCenterLocationButton;
  final bool showOverlays;
  final int buttonTopOffset;
  final bool scaleAtTop;
  final void Function(bool)? onFullscreenToggle;
  final void Function(bool)? onCenterLocationToggle;

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

  bool _centerLocation = true;

  @override
  void dispose() {
    final cameraPosition = _mapController?.cameraPosition;
    if (cameraPosition != null) {
      Settings.instance.lastMapPosition = cameraPosition;
    }
    super.dispose();
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
            setState(() => _mapController = controller);
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
        if (_mapController != null && widget.showScale)
          widget.scaleAtTop
              ? Positioned(
                  top: 10,
                  left: 10,
                  child: MapScale(mapController: _mapController!),
                )
              : Positioned(
                  bottom: 10,
                  right: 10,
                  child: MapScale(mapController: _mapController!),
                ),
        if (_mapController != null && widget.showOverlays)
          Positioned(
            top: widget.buttonTopOffset + 15,
            right: 15,
            child: Column(
              children: [
                if (widget.showFullscreenButton) ...[
                  ToggleFullscreenButton(onToggle: widget.onFullscreenToggle),
                  Defaults.sizedBox.vertical.normal,
                ],
                if (widget.showMapStylesButton) ...[
                  MapStylesButton(
                    mapController: _mapController!,
                    onStyleChange: (style) => setState(() => _mapStyle = style),
                  ),
                  Defaults.sizedBox.vertical.normal,
                ],
                if (widget.showSelectRouteButton) ...[
                  SelectRouteButton(mapController: _mapController!),
                  Defaults.sizedBox.vertical.normal,
                ],
                if (widget.showSetNorthButton) ...[
                  SetNorthButton(mapController: _mapController!),
                  Defaults.sizedBox.vertical.normal,
                ],
                if (widget.showCurrentLocationButton) ...[
                  CurrentLocationButton(
                    mapController: _mapController!,
                    centerLocation: _centerLocation,
                  ),
                  Defaults.sizedBox.vertical.normal,
                ],
                if (widget.showCenterLocationButton) ...[
                  ToggleCenterLocationButton(
                    onToggle: (centerLocation) {
                      setState(() => _centerLocation = centerLocation);
                      widget.onCenterLocationToggle?.call(centerLocation);
                    },
                  ),
                  Defaults.sizedBox.vertical.normal,
                ],
              ],
            ),
          ),
      ],
    );
  }
}
