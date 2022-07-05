import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:provider/provider.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/extensions/lat_lng_extension.dart';
import 'package:sport_log/helpers/extensions/map_controller_extension.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/message_dialog.dart';
import 'package:sport_log/widgets/main_drawer.dart';
import 'package:sport_log/widgets/pop_scopes.dart';

class OfflineMapsPage extends StatefulWidget {
  const OfflineMapsPage({super.key});

  @override
  State<OfflineMapsPage> createState() => _OfflineMapsPageState();
}

class _OfflineMapsPageState extends State<OfflineMapsPage> {
  late MapboxMapController _mapController;

  LatLng? _point1;
  LatLng? _point2;
  Circle? _point1Marker;
  Circle? _point2Marker;
  Line? _boundingBoxLine;

  double? _progress;

  List<OfflineRegion> _regions = [];

  @override
  void initState() {
    _updateRegions();
    super.initState();
  }

  @override
  void dispose() {
    if (_mapController.cameraPosition != null) {
      Settings.instance.lastMapPosition = _mapController.cameraPosition!;
    }
    super.dispose();
  }

  Future<void> _updateRegions() async {
    final regions =
        await getListOfRegions(accessToken: Config.instance.accessToken);
    setState(() => _regions = regions);
  }

  Future<void> _onMapDownload(DownloadRegionStatus status) async {
    if (status.runtimeType == Success) {
      setState(() => _progress = null);
      await showMessageDialog(context: context, text: "Download Successful");
      await _updateRegions();
      await _updatePoint2(null);
      await _updatePoint1(null);
    } else if (status.runtimeType == InProgress) {
      setState(() => _progress = (status as InProgress).progress / 100);
    } else if (status.runtimeType == Error) {
      setState(() => _progress = null);
      await showMessageDialog(context: context, text: "Download Failed");
    }
  }

  void _downloadMap() {
    if (_point1 != null && _point2 != null) {
      downloadOfflineRegion(
        OfflineRegionDefinition(
          bounds: [_point1!, _point2!].latLngBounds!,
          minZoom: 0,
          maxZoom: 16,
          mapStyleUrl: MapboxStyles.OUTDOORS,
        ),
        onEvent: _onMapDownload,
        accessToken: Config.instance.accessToken,
        metadata: <String, dynamic>{
          "datetime": DateTime.now().toIso8601String()
        },
      );
    } else {
      showMessageDialog(
        context: context,
        text: "Please mark 2 points by long pressing on the map.",
      );
    }
  }

  Future<void> _updatePoint1(LatLng? latLng) async {
    setState(() => _point1 = latLng);
    _point1Marker =
        await _mapController.updateLocationMarker(_point1Marker, _point1);
  }

  Future<void> _updatePoint2(LatLng? latLng) async {
    setState(() => _point2 = latLng);
    _point2Marker =
        await _mapController.updateLocationMarker(_point2Marker, _point2);
    _boundingBoxLine = await _mapController.updateBoundingBoxLine(
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
        body: Column(
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
                    trackCameraPosition: true,
                    onMapCreated: (MapboxMapController controller) =>
                        _mapController = controller,
                    onMapLongClick: (_, latLng) => _point1 == null
                        ? _updatePoint1(latLng)
                        : _updatePoint2(latLng),
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
                    _progress == null
                        ? ElevatedButton(
                            onPressed: _downloadMap,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(AppIcons.download),
                                Text("Download")
                              ],
                            ),
                          )
                        : LinearProgressIndicator(
                            value: _progress ?? 0.3,
                          ),
                    Defaults.sizedBox.vertical.normal,
                    Expanded(
                      child: ListView.separated(
                        itemBuilder: (_, index) => RegionCard(
                          region: _regions[index],
                          onDelete: _updateRegions,
                          key: ValueKey(_regions[index].id),
                        ),
                        separatorBuilder: (_, __) =>
                            Defaults.sizedBox.vertical.normal,
                        itemCount: _regions.length,
                      ),
                    ),
                  ],
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
  const RegionCard({required this.region, required this.onDelete, super.key});

  final OfflineRegion region;
  final VoidCallback onDelete;

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
          child: MapboxMap(
            accessToken: Config.instance.accessToken,
            styleString: MapboxStyles.OUTDOORS,
            initialCameraPosition: context.read<Settings>().lastMapPosition,
            rotateGesturesEnabled: false,
            tiltGesturesEnabled: false,
            scrollGesturesEnabled: false,
            zoomGesturesEnabled: false,
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
            onPressed: () async {
              await deleteOfflineRegion(region.id);
              onDelete();
            },
          ),
        ),
      ],
    );
  }
}
