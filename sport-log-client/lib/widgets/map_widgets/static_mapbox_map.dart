import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart'
    hide Settings, Visibility;
import 'package:provider/provider.dart';
import 'package:sport_log/helpers/lat_lng.dart';
import 'package:sport_log/helpers/map_controller.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/map_widgets/map_ready_callback.dart';
import 'package:sport_log/widgets/map_widgets/map_styles_button.dart';

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
  late final MapReadyCallback _mapReadyCallback = MapReadyCallback(_onReady);

  Future<void> _onReady(MapController mapController) async {
    if (mounted) {
      await mapController.setLatLngZoom(
        context.read<Settings>().lastMapPosition,
      );
      await mapController.disableAllGestures();
      await mapController.showScaleBar();
      await mapController.hideAttribution();
      await mapController.hideLogo();
      widget.onMapCreated?.call(mapController);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MapWidget(
      styleUri: MapStyle.outdoor.url,
      onMapCreated: (mapboxMap) async {
        mapboxMap
          ..addInteraction(
            TapInteraction.onMap(
              (gestureContext) =>
                  widget.onTap?.call(LatLng.fromPoint(gestureContext.point)),
            ),
          )
          ..addInteraction(
            LongTapInteraction.onMap(
              (gestureContext) => widget.onLongTap?.call(
                LatLng.fromPoint(gestureContext.point),
              ),
            ),
          );
        final controller = await MapController.from(mapboxMap, context);
        if (context.mounted && controller != null) {
          _mapReadyCallback.onMapCreated(controller);
        }
      },
      onMapLoadedListener: _mapReadyCallback.onMapLoaded,
    );
  }
}

class ElevationMap extends StatelessWidget {
  const ElevationMap({required this.onMapCreated, super.key});

  final void Function(ElevationMapController) onMapCreated;

  @override
  Widget build(BuildContext context) {
    // TODO avoid rendering
    // currently only works when rendered
    // it worked for some time when wrapped in Offstage but then stopped reporting elevation
    // also does not work when wrapped in Visibility(visible: false) or Opacity(opacity: 0)
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
