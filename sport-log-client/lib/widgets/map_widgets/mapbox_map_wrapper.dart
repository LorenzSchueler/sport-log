import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Settings;
import 'package:provider/provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/lat_lng.dart';
import 'package:sport_log/helpers/location_utils.dart';
import 'package:sport_log/helpers/map_controller.dart';
import 'package:sport_log/helpers/pointer.dart';
import 'package:sport_log/models/cardio/route.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/map_widgets/add_location_button.dart';
import 'package:sport_log/widgets/map_widgets/current_location_button.dart';
import 'package:sport_log/widgets/map_widgets/map_styles_button.dart';
import 'package:sport_log/widgets/map_widgets/select_route_button.dart';
import 'package:sport_log/widgets/map_widgets/set_north_button.dart';
import 'package:sport_log/widgets/map_widgets/toggle_center_location_button.dart';
import 'package:sport_log/widgets/map_widgets/toggle_fullscreen_button.dart';
import 'package:sport_log/widgets/provider_consumer.dart';

class MapboxMapWrapper extends StatefulWidget {
  const MapboxMapWrapper({
    required this.showFullscreenButton,
    required this.showMapStylesButton,
    required this.showSelectRouteButton,
    required this.showSetNorthButton,
    required this.showCurrentLocationButton,
    required this.showCenterLocationButton,
    required this.showAddLocationButton,
    this.showOverlays = true,
    this.buttonTopOffset = 0,
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

  final bool showFullscreenButton;
  final bool showMapStylesButton;
  final bool showSelectRouteButton;
  final bool showSetNorthButton;
  final bool showCurrentLocationButton;
  final bool showCenterLocationButton;
  final bool showAddLocationButton;
  final bool showOverlays;
  final int buttonTopOffset;

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
  final LocationUtils _locationUtils = LocationUtils();

  bool _centerLocation = true;
  Route? _selectedRoute;

  final NullablePointer<List<CircleAnnotation>> _currentLocationMarker =
      NullablePointer.nullPointer();
  final NullablePointer<PolylineAnnotation> _line =
      NullablePointer.nullPointer();

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
    await _mapController?.showScaleBar();
    await _mapController?.styleAttribution();
    //await _mapController?.hideAttribution();
    //await _mapController?.hideLogo();
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

  Future<void> updateRoute(Route? route) async {
    final changed = _selectedRoute != null && route != null;
    if (mounted) {
      setState(() => _selectedRoute = route);
    }
    await _mapController?.updateRouteLine(_line, _selectedRoute?.track);
    // do not change bounds if the current position was added to the route
    if (!changed) {
      await _mapController?.setBoundsFromTracks(
        _selectedRoute?.track,
        null,
        padded: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MapWidget(
          // TODO remove when fixed: https://github.com/mapbox/mapbox-maps-flutter/issues/439
          gestureRecognizers: const {
            Factory<EagerGestureRecognizer>(EagerGestureRecognizer.new),
          },
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
          onCameraChangeListener: (_) async {
            final lastMapPosition = await _mapController?.latLngZoom;
            if (lastMapPosition != null) {
              await Settings.instance.setLastMapPosition(lastMapPosition);
            }
          },
          onTapListener: (MapContentGestureContext gestureContext) =>
              widget.onTap?.call(LatLng.fromPoint(gestureContext.point)),
          onLongTapListener: (gestureContext) =>
              widget.onLongTap?.call(LatLng.fromPoint(gestureContext.point)),
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
                  SelectRouteButton(
                    selectedRoute: _selectedRoute,
                    updateRoute: updateRoute,
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
                    locationUtils: _locationUtils,
                    centerLocation: _centerLocation,
                    currentLocationMarker: _currentLocationMarker,
                  ),
                  Defaults.sizedBox.vertical.normal,
                ],
                if (widget.showCenterLocationButton) ...[
                  ToggleCenterLocationButton(
                    centerLocation: _centerLocation,
                    onToggle: () {
                      setState(() => _centerLocation = !_centerLocation);
                      widget.onCenterLocationToggle?.call(_centerLocation);
                    },
                  ),
                  Defaults.sizedBox.vertical.normal,
                ],
                ProviderConsumer.value(
                  // Consumer to detect enabled change
                  value: _locationUtils,
                  builder: (context, locationUtils, _) =>
                      widget.showAddLocationButton &&
                              _selectedRoute != null &&
                              _locationUtils.enabled
                          ? AddLocationButton(
                              route: _selectedRoute!,
                              updateRoute: updateRoute,
                              locationUtils: _locationUtils,
                            )
                          : Container(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
