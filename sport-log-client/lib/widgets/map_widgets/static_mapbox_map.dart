import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Settings;
import 'package:provider/provider.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/helpers/lat_lng.dart';
import 'package:sport_log/helpers/map_controller.dart';
import 'package:sport_log/settings.dart';

class StaticMapboxMap extends StatefulWidget {
  const StaticMapboxMap({
    this.onMapCreated,
    this.onTap,
    this.onLongTap,
    super.key,
  });

  final void Function(MapController)? onMapCreated;
  final void Function(LatLng)? onTap;
  final void Function(LatLng)? onLongTap;

  @override
  State<StaticMapboxMap> createState() => _StaticMapboxMapState();
}

class _StaticMapboxMapState extends State<StaticMapboxMap> {
  MapController? _mapController;

  Future<void> _onMapCreated(MapController mapController) async {
    _mapController = mapController;
    await mapController.disableAllGestures();
    await mapController.setScaleBarSettings();
    await mapController.hideAttribution();
    widget.onMapCreated?.call(mapController);
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

class ElevationMap extends StatelessWidget {
  const ElevationMap({required this.onMapCreated, super.key});

  final void Function(ElevationMapController) onMapCreated;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      width: 1,
      child: StaticMapboxMap(
        onMapCreated: (mapController) async {
          await mapController.setZoom(15);
          await mapController.enableTerrain("elevation-terrain-source", 0);
          onMapCreated(ElevationMapController(mapController));
        },
      ),
    );
  }
}
