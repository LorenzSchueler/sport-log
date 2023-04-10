import 'dart:io';

import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:mapbox_api/mapbox_api.dart';
import 'package:result_type/result_type.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/lat_lng.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/cardio/position.dart';

enum RoutePlanningError {
  noInternet,
  unknown;

  String get message {
    return this == RoutePlanningError.noInternet
        ? 'No Internet connection.'
        : 'An unknown Error occurred.';
  }
}

class RoutePlanningUtils {
  static final _logger = Logger("RoutePlanningUtils");

  static Future<Result<List<Position>, RoutePlanningError>> matchLocations(
    List<Position> markedPositions,
    Future<double?> Function(LatLng)? getElevation,
  ) async {
    DirectionsApiResponse response;
    try {
      response = await Defaults.mapboxApi.directions.request(
        profile: NavigationProfile.WALKING,
        overview: NavigationOverview.FULL,
        coordinates:
            markedPositions.map((e) => [e.latitude, e.longitude]).toList(),
      );
    } on SocketException {
      return Failure(RoutePlanningError.noInternet);
    }
    if (response.routes != null && response.routes!.isNotEmpty) {
      final navRoute = response.routes![0];
      final track = <Position>[];
      final latLngs = PolylinePoints()
          .decodePolyline(navRoute.geometry as String)
          .map((p) => LatLng(lat: p.latitude, lng: p.longitude))
          .toList();
      for (final latLng in latLngs) {
        final elevation = await getElevation?.call(latLng);
        track.add(
          Position(
            latitude: latLng.lat,
            longitude: latLng.lng,
            elevation: elevation ?? track.last.elevation,
            distance: track.isEmpty ? 0 : track.last.addDistanceTo(latLng),
            time: Duration.zero,
          ),
        );
      }
      return Success(track);
    } else {
      _logger.i("mapbox api error ${response.error.runtimeType}");
      return Failure(RoutePlanningError.unknown);
    }
  }
}
