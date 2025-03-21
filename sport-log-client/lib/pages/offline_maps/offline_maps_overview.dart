import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Settings;
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/lat_lng.dart';
import 'package:sport_log/helpers/map_controller.dart';
import 'package:sport_log/helpers/map_download_utils.dart';
import 'package:sport_log/helpers/pointer.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/dialogs.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/map_widgets/mapbox_map_wrapper.dart';
import 'package:sport_log/widgets/map_widgets/static_mapbox_map.dart';
import 'package:sport_log/widgets/pop_scopes.dart';
import 'package:sport_log/widgets/provider_consumer.dart';

class OfflineMapsPage extends StatefulWidget {
  const OfflineMapsPage({super.key});

  @override
  State<OfflineMapsPage> createState() => _OfflineMapsPageState();
}

class _OfflineMapsPageState extends State<OfflineMapsPage> {
  MapController? _mapController;

  LatLng? _point1;
  LatLng? _point2;
  final NullablePointer<CircleAnnotation> _point1Marker =
      NullablePointer.nullPointer();
  final NullablePointer<CircleAnnotation> _point2Marker =
      NullablePointer.nullPointer();
  final NullablePointer<PolylineAnnotation> _boundingBoxLine =
      NullablePointer.nullPointer();

  void _onMapCreated(MapController mapController) {
    _mapController = mapController;
  }

  Future<void> onSuccess() async {
    await _updatePoint2(null);
    await _updatePoint1(null);
    if (mounted) {
      await showMessageDialog(
        context: context,
        title: "Download Successful",
        text: "Map region has been saved and can be used offline.",
      );
    }
  }

  Future<void> onError(String message) async {
    if (mounted) {
      await showMessageDialog(
        context: context,
        title: "Download Failed",
        text: message,
      );
    }
  }

  Future<void> _downloadMap(MapDownloadUtils mapDownloadUtils) async {
    if (_point1 != null && _point2 != null) {
      final bounds = [_point1!, _point2!].latLngBounds!;
      await mapDownloadUtils.downloadRegion(bounds);
    } else {
      await showMessageDialog(
        context: context,
        title: "Usage",
        text: "Mark 2 points by long pressing on the map.",
      );
    }
  }

  Future<void> _updatePoint1(LatLng? latLng) async {
    setState(() => _point1 = latLng);
    await _mapController?.updateTrackMarker(_point1Marker, _point1);
  }

  Future<void> _updatePoint2(LatLng? latLng) async {
    setState(() => _point2 = latLng);
    await _mapController?.updateTrackMarker(_point2Marker, _point2);
    await _mapController?.updateBoundingBoxLine(
      _boundingBoxLine,
      [_point1, _point2].whereType<LatLng>().latLngBounds,
    );
  }

  @override
  Widget build(BuildContext context) {
    return NeverPop(
      child: Scaffold(
        appBar: AppBar(title: const Text("Offline Maps")),
        drawer: const MainDrawer(selectedRoute: Routes.offlineMaps),
        body: Column(
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 400,
                  child: MapboxMapWrapper(
                    showFullscreenButton: false,
                    showMapStylesButton: false,
                    showSelectRouteButton: false,
                    showSetNorthButton: false,
                    showCurrentLocationButton: false,
                    showCenterLocationButton: false,
                    showAddLocationButton: false,
                    onMapCreated: _onMapCreated,
                    onLongTap:
                        (latLng) =>
                            _point1 == null
                                ? _updatePoint1(latLng)
                                : _updatePoint2(latLng),
                    rotateGesturesEnabled: false,
                  ),
                ),
                if (_point1 != null)
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: FloatingActionButton.small(
                      heroTag: null,
                      onPressed:
                          () =>
                              _point2 != null
                                  ? _updatePoint2(null)
                                  : _updatePoint1(null),
                      child: const Icon(AppIcons.undo),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: Defaults.edgeInsets.normal,
                child: ProviderConsumer<MapDownloadUtils>(
                  create:
                      (_) => MapDownloadUtils(
                        onSuccess: onSuccess,
                        onError: onError,
                      )..init(),
                  builder: (context, mapDownloadUtils, _) {
                    return Column(
                      children: [
                        mapDownloadUtils.progress == null
                            ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text("Max Zoom"),
                                Slider(
                                  value: mapDownloadUtils.maxZoom.toDouble(),
                                  label: mapDownloadUtils.maxZoom.toString(),
                                  max: 16,
                                  divisions: 16,
                                  onChanged: (zoom) {
                                    mapDownloadUtils.maxZoom = zoom.round();
                                  },
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    icon: const Icon(AppIcons.download),
                                    label: const Text("Download"),
                                    style:
                                        _point1 == null || _point2 == null
                                            ? ButtonStyle(
                                              backgroundColor:
                                                  WidgetStatePropertyAll(
                                                    Theme.of(
                                                      context,
                                                    ).disabledColor,
                                                  ),
                                            )
                                            : null,
                                    onPressed:
                                        () => _downloadMap(mapDownloadUtils),
                                  ),
                                ),
                              ],
                            )
                            : LinearProgressIndicator(
                              value: mapDownloadUtils.progress,
                            ),
                        Defaults.sizedBox.vertical.normal,
                        Expanded(
                          child: ListView.separated(
                            itemBuilder:
                                (_, index) => RegionCard(
                                  region: mapDownloadUtils.regions[index],
                                  mapDownloadUtils: mapDownloadUtils,
                                  key: ValueKey(
                                    mapDownloadUtils
                                        .regions[index]
                                        .tileRegion
                                        .id,
                                  ),
                                ),
                            separatorBuilder:
                                (_, __) => Defaults.sizedBox.vertical.normal,
                            itemCount: mapDownloadUtils.regions.length,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RegionCard extends StatelessWidget {
  const RegionCard({
    required this.region,
    required this.mapDownloadUtils,
    super.key,
  });

  final OfflineRegion region;
  final MapDownloadUtils mapDownloadUtils;

  Future<void> _onMapCreated(MapController mapController) async {
    final bounds = LatLngBounds.fromList(
      (region.metadata["bounds"]! as List).cast<double>(),
    );
    await mapController.setBoundsX(bounds, padded: true);
    await mapController.addBoundingBoxLine(bounds);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 150,
          child: StaticMapboxMap(onMapCreated: _onMapCreated),
        ),
        Positioned(
          top: 10,
          left: 10,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateTime.parse(
                  region.metadata["datetime"]! as String,
                ).humanDate,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: Theme.of(context).colorScheme.surface,
                ),
              ),
              Text(
                "${region.tileRegion.completedResourceCount} Tiles / ${(region.tileRegion.completedResourceSize / 1000000).round()} MB",
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context).colorScheme.surface,
                ),
              ),
              Text(
                "Zoom ${region.metadata["minZoom"]} - ${region.metadata["maxZoom"]}",
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context).colorScheme.surface,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: FloatingActionButton.small(
            heroTag: null,
            child: const Icon(AppIcons.delete),
            onPressed: () => mapDownloadUtils.deleteRegion(region.tileRegion),
          ),
        ),
      ],
    );
  }
}
