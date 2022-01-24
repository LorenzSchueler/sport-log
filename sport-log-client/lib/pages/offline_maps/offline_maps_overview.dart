import 'dart:math';

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

  LatLng? point1;
  LatLng? point2;
  Circle? point1Marker;
  Circle? point2Marker;
  Line? boundingBoxLine;

  double? progress;

  void onMapDownload(DownloadRegionStatus status) {
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
    if (point1 != null && point2 != null) {
      LatLng northeast = LatLng(
        max(point1!.latitude, point2!.latitude),
        max(point1!.longitude, point2!.longitude),
      );
      LatLng southwest = LatLng(
        min(point1!.latitude, point2!.latitude),
        min(point1!.longitude, point2!.longitude),
      );
      _logger.i("northwest: $northeast\n southeast: $southwest");
      downloadOfflineRegion(
          OfflineRegionDefinition(
            bounds: LatLngBounds(
              northeast: northeast,
              southwest: southwest,
            ),
            minZoom: 6,
            maxZoom: 18,
            mapStyleUrl: Defaults.mapbox.style.outdoor,
          ),
          onEvent: onMapDownload,
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

  void updatePoint1(LatLng? latLng) async {
    setState(() {
      point1 = latLng;
    });
    if (point1Marker != null) {
      _mapController.removeCircle(point1Marker!);
    }
    if (point1 != null) {
      point1Marker = await _mapController.addCircle(CircleOptions(
        circleRadius: 8.0,
        circleColor: Defaults.mapbox.markerColor,
        circleOpacity: 0.5,
        geometry: point1,
      ));
    }
  }

  void updatePoint2(LatLng? latLng) async {
    setState(() {
      point2 = latLng;
    });
    if (point2Marker != null) {
      _mapController.removeCircle(point2Marker!);
    }
    if (boundingBoxLine != null) {
      _mapController.removeLine(boundingBoxLine!);
    }
    if (point2 != null) {
      point2Marker = await _mapController.addCircle(CircleOptions(
        circleRadius: 8.0,
        circleColor: Defaults.mapbox.markerColor,
        circleOpacity: 0.5,
        geometry: point2,
      ));
      boundingBoxLine = await _mapController.addLine(
        LineOptions(lineColor: "red", lineWidth: 3, geometry: [
          LatLng(point1!.latitude, point1!.longitude),
          LatLng(point1!.latitude, point2!.longitude),
          LatLng(point2!.latitude, point2!.longitude),
          LatLng(point2!.latitude, point1!.longitude),
          LatLng(point1!.latitude, point1!.longitude)
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
              onMapLongClick: (_, latLng) =>
                  point1 == null ? updatePoint1(latLng) : updatePoint2(latLng),
            ),
          ),
          ElevatedButton(onPressed: download, child: const Text("download")),
          ElevatedButton(
              onPressed: () =>
                  point2 != null ? updatePoint2(null) : updatePoint1(null),
              child: const Text("undo")),
          LinearProgressIndicator(
            value: progress ?? 0.3,
          ),
        ]));
  }
}
