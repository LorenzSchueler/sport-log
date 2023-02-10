import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Settings;
import 'package:provider/provider.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/helpers/extensions/map_controller_extension.dart';
import 'package:sport_log/helpers/lat_lng.dart';
import 'package:sport_log/settings.dart';

class StaticMapboxMap extends StatelessWidget {
  StaticMapboxMap({
    this.onMapCreated,
    this.onTap,
    this.onLongTap,
    super.key,
  });

  final void Function(MapboxMap)? onMapCreated;
  final void Function(LatLng)? onTap;
  final void Function(LatLng)? onLongTap;

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
    onMapCreated?.call(mapController);
  }

  @override
  Widget build(BuildContext context) {
    return MapWidget(
      resourceOptions:
          ResourceOptions(accessToken: Config.instance.accessToken),
      styleUri: MapboxStyles.OUTDOORS,
      cameraOptions: context.read<Settings>().lastMapPosition.toCameraOptions(),
      onMapCreated: _onMapCreated,
      onTapListener: _mapController?.invokeWithLatLng(onTap),
      onLongTapListener: _mapController?.invokeWithLatLng(onLongTap),
    );
  }
}
