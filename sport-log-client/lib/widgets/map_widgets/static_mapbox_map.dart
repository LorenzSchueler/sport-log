import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Settings;
import 'package:provider/provider.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/helpers/extensions/map_controller_extension.dart';
import 'package:sport_log/helpers/lat_lng.dart';
import 'package:sport_log/settings.dart';

class StaticMapboxMap extends StatefulWidget {
  const StaticMapboxMap({
    this.onMapCreated,
    this.onTap,
    this.onLongTap,
    super.key,
  });

  final void Function(MapboxMap)? onMapCreated;
  final void Function(LatLng)? onTap;
  final void Function(LatLng)? onLongTap;

  @override
  State<StaticMapboxMap> createState() => _StaticMapboxMapState();
}

class _StaticMapboxMapState extends State<StaticMapboxMap> {
  MapboxMap? _mapController;

  Future<void> _onMapCreated(MapboxMap mapController) async {
    _mapController = mapController;
    await mapController.gestures.updateSettings(
      GesturesSettings(
        doubleTapToZoomInEnabled: false,
        doubleTouchToZoomOutEnabled: false,
        rotateEnabled: false,
        scrollEnabled: false,
        pitchEnabled: false,
        pinchToZoomEnabled: false,
        quickZoomEnabled: false,
        pinchPanEnabled: false,
        simultaneousRotateAndPinchToZoomEnabled: false,
      ),
    );
    await mapController.scaleBar.updateSettings(
      ScaleBarSettings(position: OrnamentPosition.BOTTOM_RIGHT),
    );
    widget.onMapCreated?.call(mapController);
  }

  @override
  Widget build(BuildContext context) {
    return MapWidget(
      resourceOptions:
          ResourceOptions(accessToken: Config.instance.accessToken),
      styleUri: MapboxStyles.OUTDOORS,
      cameraOptions: context.read<Settings>().lastMapPosition.toCameraOptions(),
      onMapCreated: _onMapCreated,
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
    );
  }
}
