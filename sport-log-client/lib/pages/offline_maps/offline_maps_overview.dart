import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/secrets.dart';
import 'package:sport_log/widgets/main_drawer.dart';

class OfflineMapsPage extends StatefulWidget {
  const OfflineMapsPage({Key? key}) : super(key: key);

  @override
  State<OfflineMapsPage> createState() => OfflineMapsPageState();
}

class OfflineMapsPageState extends State<OfflineMapsPage> {
  final _logger = Logger('OfflineMapsPage');

  late MapboxMapController _mapController;

  LatLng? northeast;
  LatLng? southwest;
  Circle? northeastPoint;
  Circle? southwestPoint;
  Line? boundingBoxLine;

  double? progress;

  void onEvent(DownloadRegionStatus status) {
    if (status.runtimeType == Success) {
      // ...
    } else if (status.runtimeType == InProgress) {
      setState(() {
        progress = (status as InProgress).progress;
      });
    } else if (status.runtimeType == Error) {
      // ...
    }
  }

  void download() {
    if (northeast != null && southwest != null) {
      downloadOfflineRegion(
          OfflineRegionDefinition(
            bounds: LatLngBounds(
              northeast: northeast!,
              southwest: southwest!,
            ),
            minZoom: 6,
            maxZoom: 18,
            mapStyleUrl: Defaults.mapbox.style.outdoor,
          ),
          onEvent: onEvent,
          accessToken: Secrets.mapboxAccessToken);
    } else {
      showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text("Unknown BoundingBox"),
                content:
                    const Text("Please set northeast and southwest points"),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("OK")),
                ],
              ));
    }
  }

  void updateNorthEastPoint() async {
    if (northeastPoint != null) {
      _mapController.removeCircle(northeastPoint!);
    }
    if (northeast != null) {
      northeastPoint = await _mapController.addCircle(CircleOptions(
        circleRadius: 8.0,
        circleColor: Defaults.mapbox.markerColor,
        circleOpacity: 0.5,
        geometry: northeast,
      ));
    }
  }

  void updateSouthWestPoint() async {
    if (southwestPoint != null) {
      _mapController.removeCircle(southwestPoint!);
    }
    if (boundingBoxLine != null) {
      _mapController.removeLine(boundingBoxLine!);
    }
    if (southwest != null) {
      southwestPoint = await _mapController.addCircle(CircleOptions(
        circleRadius: 8.0,
        circleColor: Defaults.mapbox.markerColor,
        circleOpacity: 0.5,
        geometry: southwest,
      ));
      boundingBoxLine = await _mapController.addLine(
        LineOptions(lineColor: "red", lineWidth: 3, geometry: [
          LatLng(northeast!.latitude, northeast!.longitude),
          LatLng(northeast!.latitude, southwest!.longitude),
          LatLng(southwest!.latitude, southwest!.longitude),
          LatLng(southwest!.latitude, northeast!.longitude),
          LatLng(northeast!.latitude, northeast!.longitude)
        ]),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Offline Maps")),
        drawer: const MainDrawer(selectedRoute: Routes.offlineMaps),
        body: Column(children: [
          SizedBox(
            height: 250,
            child: MapboxMap(
              accessToken: Secrets.mapboxAccessToken,
              styleString: Defaults.mapbox.style.outdoor,
              initialCameraPosition: const CameraPosition(
                zoom: 13.0,
                target: LatLng(47.27, 11.33),
              ),
              onMapCreated: (MapboxMapController controller) =>
                  _mapController = controller,
              onMapLongClick: (_, latLng) {
                if (northeast == null) {
                  northeast = latLng;
                  updateNorthEastPoint();
                } else {
                  southwest = latLng;
                  updateSouthWestPoint();
                }
              },
            ),
          ),
          const Text("not implemented"),
          ElevatedButton(onPressed: download, child: const Text("download")),
          ElevatedButton(
              onPressed: () {
                if (southwest != null) {
                  southwest = null;
                  updateSouthWestPoint();
                } else {
                  northeast = null;
                  updateNorthEastPoint();
                }
              },
              child: const Text("undo")),
          LinearProgressIndicator(
            value: progress ?? 0.3,
          ),
        ]));
  }
}
