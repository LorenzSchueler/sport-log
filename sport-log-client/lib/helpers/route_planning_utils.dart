import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:mapbox_api/mapbox_api.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/cardio/position.dart';
import 'package:sport_log/widgets/snackbar.dart';

class RoutePlanningUtils {
  final _logger = Logger("RoutePlanningUtils");

  Future<List<Position>?> matchLocations(
    BuildContext context,
    List<Position> markedPositions,
  ) async {
    DirectionsApiResponse response;
    try {
      response = await Defaults.mapboxApi.directions.request(
        profile: NavigationProfile.WALKING,
        geometries: NavigationGeometries.POLYLINE,
        coordinates:
            markedPositions.map((e) => [e.latitude, e.longitude]).toList(),
      );
    } on SocketException {
      showSimpleToast(context, 'No Internet connection.');
      return null;
    }
    if (response.error != null) {
      if (response.error is NavigationNoRouteError) {
        _logger.i(response.error);
      } else if (response.error is NavigationNoSegmentError) {
        _logger.i(response.error);
      } else {
        _logger.i(response.error.runtimeType);
      }
    } else if (response.routes != null && response.routes!.isNotEmpty) {
      NavigationRoute navRoute = response.routes![0];
      List<Position> track = [];
      for (final pointLatLng
          in PolylinePoints().decodePolyline(navRoute.geometry as String)) {
        track.add(
          Position(
            latitude: pointLatLng.latitude,
            longitude: pointLatLng.longitude,
            elevation: 0, // TODO
            distance: track.isEmpty
                ? 0
                : track.last
                    .addDistanceTo(pointLatLng.latitude, pointLatLng.longitude),
            time: Duration.zero,
          ),
        );
      }
      _logger
        ..i("mapbox distance ${navRoute.distance}")
        ..i("own distance ${track.last.distance}");
      return track;
    }
    return null;
  }
}
