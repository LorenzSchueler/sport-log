import 'package:flutter/material.dart' hide Route;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Settings;
import 'package:provider/provider.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/lat_lng.dart';
import 'package:sport_log/helpers/map_controller.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/map_widgets/current_location_button.dart';
import 'package:sport_log/widgets/map_widgets/map_styles_button.dart';
import 'package:sport_log/widgets/map_widgets/select_route_button.dart';
import 'package:sport_log/widgets/map_widgets/set_north_button.dart';
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

  final void Function(MapController)? onMapCreated;
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
  MapController? _mapController;

  bool _centerLocation = true;

  @override
  void didUpdateWidget(MapboxMapWrapper old) {
    super.didUpdateWidget(old);
    _setMapSettings();
  }

  Future<void> _setMapSettings() async {
    await _mapController?.setGestureSettings(
      doubleTapZoomEnabled: widget.doubleClickZoomEnabled,
      zoomEnabled: widget.zoomGesturesEnabled,
      rotateEnabled: widget.rotateGesturesEnabled,
      scrollEnabled: widget.scrollGesturesEnabled,
      pitchEnabled: widget.pitchGestureEnabled,
    );
    await _mapController?.setScaleBarSettings(
      position: widget.scaleAtTop
          ? OrnamentPosition.TOP_LEFT
          : OrnamentPosition.BOTTOM_RIGHT,
      enabled: widget.showScale,
    );
    await _mapController?.hideAttribution();
    await _mapController?.hideCompass();
  }

  Future<void> _onMapCreated(MapController mapController) async {
    _mapController = mapController;
    await _setMapSettings();
    widget.onMapCreated?.call(mapController);
    if (mounted) {
      setState(() {});
    }
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
          onMapCreated: (mapboxMap) async {
            final controller = await MapController.from(mapboxMap, context);
            if (controller != null) {
              await _onMapCreated(controller);
            }
          },
          onTapListener: (coord) async {
            final latLng = await _mapController?.screenCoordToLatLng(coord);
            if (latLng != null) {
              // TODO fix until upstream is fixed
              final latLng = LatLng(lat: coord.x, lng: coord.y);
              widget.onTap?.call(latLng);
            }
          },
          onLongTapListener: (coord) async {
            final latLng = await _mapController?.screenCoordToLatLng(coord);
            if (latLng != null) {
              // TODO fix until upstream is fixed
              final latLng = LatLng(lat: coord.x, lng: coord.y);
              widget.onLongTap?.call(latLng);
            }
          },
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
                  MapStylesButton(mapController: _mapController!),
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
