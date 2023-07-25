import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Settings;
import 'package:provider/provider.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/helpers/lat_lng.dart';
import 'package:sport_log/helpers/map_controller.dart';
import 'package:sport_log/settings.dart';

class StaticMapboxMap extends StatelessWidget {
  const StaticMapboxMap({
    this.onMapCreated,
    this.onTap,
    this.onLongTap,
    super.key,
  });

  final void Function(MapController)? onMapCreated;
  final void Function(LatLng)? onTap;
  final void Function(LatLng)? onLongTap;

  Future<void> _onMapCreated(MapController mapController) async {
    await mapController.disableAllGestures();
    await mapController.setScaleBarSettings();
    await mapController.hideAttribution();
    onMapCreated?.call(mapController);
  }

  @override
  Widget build(BuildContext context) {
    return MapWidget(
      resourceOptions:
          ResourceOptions(accessToken: Config.instance.accessToken),
      styleUri: MapboxStyles.OUTDOORS,
      cameraOptions: context.read<Settings>().lastMapPosition.toCameraOptions(),
      onMapCreated: (mapboxMap) async {
        final controller = await MapController.from(mapboxMap, context);
        if (controller != null) {
          await _onMapCreated(controller);
        }
      },
      onTapListener: (_, point) => onTap?.call(LatLng.fromMap(point)),
      onLongTapListener: (_, point) => onLongTap?.call(LatLng.fromMap(point)),
    );
  }
}

class ElevationMap extends StatelessWidget {
  const ElevationMap({required this.onMapCreated, super.key});

  final void Function(ElevationMapController) onMapCreated;

  @override
  Widget build(BuildContext context) {
    return Offstage(
      child: SizedBox(
        height: 1,
        width: 1,
        child: StaticMapboxMap(
          onMapCreated: (mapController) async {
            await mapController.setZoom(15);
            await mapController.enableTerrain("elevation-terrain-source", 0);
            onMapCreated(ElevationMapController(mapController));
          },
        ),
      ),
    );
  }
}
