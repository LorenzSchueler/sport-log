import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Settings;
import 'package:sport_log/defaults.dart';
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

  Future<void> _onMapCreated(MapController mapController) async {
    _mapController = mapController;
  }

  MapDownloadUtils createMapDownloadUtils() {
    return MapDownloadUtils(
      // ignore: prefer-extracting-callbacks
      onSuccess: () async {
        await _updatePoint2(null);
        await _updatePoint1(null);
        if (mounted) {
          await showMessageDialog(
            context: context,
            text: "Download Successful",
          );
        }
      },
      onError: () async {
        await showMessageDialog(context: context, text: "Download Failed");
      },
    );
  }

  // ignore: avoid-unused-parameters
  Future<void> _downloadMap(MapDownloadUtils mapDownloadUtils) async {
    if (_point1 != null && _point2 != null) {
      //final bounds = [_point1!, _point2!].latLngBounds!;
      //await mapDownloadUtils.downloadRegion(bounds); TODO map download
    } else {
      await showMessageDialog(
        context: context,
        text: "Please mark 2 points by long pressing on the map.",
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
        body: ProviderConsumer<MapDownloadUtils>(
          create: (_) => createMapDownloadUtils(),
          builder: (context, mapDownloadUtils, _) {
            return Column(
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
                        onMapCreated: _onMapCreated,
                        onLongTap: (latLng) => _point1 == null
                            ? _updatePoint1(latLng)
                            : _updatePoint2(latLng),
                        rotateGesturesEnabled: false,
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: FloatingActionButton.small(
                        heroTag: null,
                        child: const Icon(AppIcons.undo),
                        onPressed: () => _point2 != null
                            ? _updatePoint2(null)
                            : _updatePoint1(null),
                      ),
                    )
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: Defaults.edgeInsets.normal,
                    child: Column(
                      children: [
                        mapDownloadUtils.progress == null
                            ? ElevatedButton(
                                onPressed: () => _downloadMap(mapDownloadUtils),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(AppIcons.download),
                                    Text("Download")
                                  ],
                                ),
                              )
                            : LinearProgressIndicator(
                                value: mapDownloadUtils.progress,
                              ),
                        Defaults.sizedBox.vertical.normal,
                        Expanded(
                          child: ListView.separated(
                            itemBuilder: (_, index) => RegionCard(
                              //region: mapDownloadUtils.regions[index],
                              mapDownloadUtils: mapDownloadUtils,
                              //key: ValueKey(mapDownloadUtils.regions[index].id),
                            ),
                            separatorBuilder: (_, __) =>
                                Defaults.sizedBox.vertical.normal,
                            itemCount: 0, //mapDownloadUtils.regions.length,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class RegionCard extends StatelessWidget {
  const RegionCard({
    //required this.region,
    required this.mapDownloadUtils,
    super.key,
  });

  //final OfflineRegion region;
  final MapDownloadUtils mapDownloadUtils;

  // ignore: avoid-unused-parameters
  Future<void> _onMapCreated(MapController mapController) async {
    //await mapController.setBoundsX(
    //region.definition.bounds,
    //padded: true,
    //);
    //await mapController.addBoundingBoxLine([
    //region.definition.bounds.northeast,
    //region.definition.bounds.southwest
    //].latLngBounds);
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
          child: Text(
            "", // DateTime.parse(region.metadata["datetime"] as String).toHumanDate(),
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: Theme.of(context).colorScheme.background,
                ),
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: FloatingActionButton.small(
            heroTag: null,
            child: const Icon(AppIcons.delete),
            onPressed: () {}, //=> mapDownloadUtils.deleteRegion(region),
          ),
        ),
      ],
    );
  }
}
