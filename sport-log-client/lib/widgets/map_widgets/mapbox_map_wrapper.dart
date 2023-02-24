import 'package:flutter/material.dart' hide Route;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Settings;
import 'package:provider/provider.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/map_controller_extension.dart';
import 'package:sport_log/helpers/lat_lng.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/map_widgets/current_location_button.dart';
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
    this.initStyleUri = MapboxStyles.OUTDOORS,
    this.initialCameraPosition,
    this.onMapCreated,
    this.onTap,
    this.onLongTap,
    this.rotateGesturesEnabled = true,
    this.scrollGesturesEnabled = true,
    this.zoomGesturesEnabled = true,
    this.doubleClickZoomEnabled = true,
    this.pitchGestureEnabled = true,
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

  final String initStyleUri;

  /// defaults to [Settings.lastMapPosition]
  final LatLngZoom? initialCameraPosition;

  final void Function(MapboxMap)? onMapCreated;
  final void Function(LatLng)? onTap;
  final void Function(LatLng)? onLongTap;

  final bool rotateGesturesEnabled;
  final bool scrollGesturesEnabled;
  final bool zoomGesturesEnabled;
  final bool doubleClickZoomEnabled;
  final bool pitchGestureEnabled;

  @override
  State<MapboxMapWrapper> createState() => _MapboxMapWrapperState();
}

class _MapboxMapWrapperState extends State<MapboxMapWrapper> {
  MapboxMap? _mapController;
  LineManager? _lineManager;
  CircleManager? _circleManager;

  bool _centerLocation = true;

  Future<void> _onMapCreated(MapboxMap mapController) async {
    _mapController = mapController;
    _lineManager = LineManager(
      await mapController.annotations.createPolylineAnnotationManager(),
    );
    _circleManager = CircleManager(
      await mapController.annotations.createCircleAnnotationManager(),
    );
    await mapController.gestures.updateSettings(
      GesturesSettings(
        doubleTapToZoomInEnabled: widget.doubleClickZoomEnabled,
        doubleTouchToZoomOutEnabled: false,
        rotateEnabled: widget.rotateGesturesEnabled,
        scrollEnabled: widget.scrollGesturesEnabled,
        pitchEnabled: widget.pitchGestureEnabled,
        pinchToZoomEnabled: widget.zoomGesturesEnabled,
        quickZoomEnabled: false,
        pinchPanEnabled: false,
        simultaneousRotateAndPinchToZoomEnabled:
            widget.rotateGesturesEnabled && widget.zoomGesturesEnabled,
      ),
    );
    await mapController.compass.updateSettings(CompassSettings(enabled: false));
    await mapController.scaleBar.updateSettings(
      ScaleBarSettings(
        enabled: widget.showScale,
        position: widget.scaleAtTop
            ? OrnamentPosition.TOP_LEFT
            : OrnamentPosition.BOTTOM_RIGHT,
      ),
    );
    if (mounted) {
      setState(() {});
    }
    widget.onMapCreated?.call(mapController);
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    final lastMapPosition = await _mapController?.latLngZoom;
    if (lastMapPosition != null) {
      Settings.instance.lastMapPosition = lastMapPosition;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MapWidget(
          resourceOptions:
              ResourceOptions(accessToken: Config.instance.accessToken),
          styleUri: widget.initStyleUri,
          cameraOptions: (widget.initialCameraPosition ??
                  context.read<Settings>().lastMapPosition)
              .toCameraOptions(),
          onMapCreated: _onMapCreated,
          onTapListener: _mapController != null
              ? (coord) async => widget.onTap
                  ?.call(await _mapController!.screenCoordToLatLng(coord))
              : null,
          onLongTapListener: _mapController != null
              ? (coord) async => widget.onLongTap
                  ?.call(await _mapController!.screenCoordToLatLng(coord))
              : null,
        ),
        if (_mapController != null &&
            _circleManager != null &&
            _lineManager != null &&
            widget.showOverlays)
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
                  MapStylesButton(mapController: _mapController!),
                  Defaults.sizedBox.vertical.normal,
                ],
                if (widget.showSelectRouteButton) ...[
                  SelectRouteButton(
                    mapController: _mapController!,
                    lineManager: _lineManager!,
                  ),
                  Defaults.sizedBox.vertical.normal,
                ],
                if (widget.showSetNorthButton) ...[
                  SetNorthButton(mapController: _mapController!),
                  Defaults.sizedBox.vertical.normal,
                ],
                if (widget.showCurrentLocationButton) ...[
                  CurrentLocationButton(
                    mapController: _mapController!,
                    circleManager: _circleManager!,
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
