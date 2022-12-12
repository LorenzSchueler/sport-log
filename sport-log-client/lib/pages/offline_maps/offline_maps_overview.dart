import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:provider/provider.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/extensions/lat_lng_extension.dart';
import 'package:sport_log/helpers/extensions/map_controller_extension.dart';
import 'package:sport_log/helpers/map_download_utils.dart';
import 'package:sport_log/helpers/pointer.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/message_dialog.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/map_widgets/static_mapbox_map.dart';
import 'package:sport_log/widgets/pop_scopes.dart';
import 'package:sport_log/widgets/provider_consumer.dart';

class OfflineMapsPage extends StatefulWidget {
  const OfflineMapsPage({super.key});

  @override
  State<OfflineMapsPage> createState() => _OfflineMapsPageState();
}

class _OfflineMapsPageState extends State<OfflineMapsPage> {
  late MapboxMapController _mapController;

  LatLng? _point1;
  LatLng? _point2;
  final NullablePointer<Circle> _point1Marker = NullablePointer.nullPointer();
  final NullablePointer<Circle> _point2Marker = NullablePointer.nullPointer();
  final NullablePointer<Line> _boundingBoxLine = NullablePointer.nullPointer();

  @override
  void dispose() {
    if (_mapController.cameraPosition != null) {
      Settings.instance.lastMapPosition = _mapController.cameraPosition!;
    }
    super.dispose();
  }

  MapDownloadUtils createMapDownloadUtils() {
    return MapDownloadUtils(
      onSuccess: () async {
        await _updatePoint2(null);
        await _updatePoint1(null);
        await showMessageDialog(context: context, text: "Download Successful");
      },
      onError: () async {
        await showMessageDialog(context: context, text: "Download Failed");
      },
    );
  }

  Future<void> _downloadMap(MapDownloadUtils mapDownloadUtils) async {
    if (_point1 != null && _point2 != null) {
      final bounds = [_point1!, _point2!].latLngBounds!;
      await mapDownloadUtils.downloadRegion(bounds);
    } else {
      await showMessageDialog(
        context: context,
        text: "Please mark 2 points by long pressing on the map.",
      );
    }
  }

  Future<void> _updatePoint1(LatLng? latLng) async {
    setState(() => _point1 = latLng);
    await _mapController.updateLocationMarker(_point1Marker, _point1);
  }

  Future<void> _updatePoint2(LatLng? latLng) async {
    setState(() => _point2 = latLng);
    await _mapController.updateLocationMarker(_point2Marker, _point2);
    await _mapController.updateBoundingBoxLine(
      _boundingBoxLine,
      _point1,
      _point2,
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
                      child: MapboxMap(
                        accessToken: Config.instance.accessToken,
                        styleString: MapboxStyles.OUTDOORS,
                        initialCameraPosition:
                            context.read<Settings>().lastMapPosition,
                        onMapCreated: (MapboxMapController controller) =>
                            _mapController = controller,
                        onMapLongClick: (_, latLng) => _point1 == null
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
                  child: Container(
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
                              region: mapDownloadUtils.regions[index],
                              mapDownloadUtils: mapDownloadUtils,
                              key: ValueKey(mapDownloadUtils.regions[index].id),
                            ),
                            separatorBuilder: (_, __) =>
                                Defaults.sizedBox.vertical.normal,
                            itemCount: mapDownloadUtils.regions.length,
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
    required this.region,
    required this.mapDownloadUtils,
    super.key,
  });

  final OfflineRegion region;
  final MapDownloadUtils mapDownloadUtils;

  Future<void> _setBoundsAndBoundingBoxLine(
    MapboxMapController sessionMapController,
  ) async {
    await sessionMapController.setBounds(
      region.definition.bounds,
      padded: true,
    );
    await sessionMapController.addBoundingBoxLine(
      region.definition.bounds.northeast,
      region.definition.bounds.southwest,
    );
  }

  @override
  Widget build(BuildContext context) {
    late final MapboxMapController sessionMapController;
    return Stack(
      children: [
        SizedBox(
          height: 150,
          child: StaticMapboxMap(
            onMapCreated: (MapboxMapController controller) =>
                sessionMapController = controller,
            onStyleLoadedCallback: () =>
                _setBoundsAndBoundingBoxLine(sessionMapController),
          ),
        ),
        Positioned(
          top: 10,
          left: 10,
          child: Text(
            DateTime.parse(region.metadata["datetime"] as String).toHumanDate(),
            style: Theme.of(context).textTheme.subtitle2!.copyWith(
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
            onPressed: () => mapDownloadUtils.deleteRegion(region),
          ),
        ),
      ],
    );
  }
}
