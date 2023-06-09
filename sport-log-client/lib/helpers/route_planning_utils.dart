import 'dart:io';

import 'package:collection/collection.dart';
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

  // Remove parts that are too far from the marked points and replace them with straight line.
  static List<Position> _adjustTrack(
    List<Position> track,
    List<Position> markedPositions,
  ) {
    var searchStart = 0;
    var deleteBetween = false;
    for (final markedPos in markedPositions) {
      var (distance, index) = markedPos.minDistanceTo(track.slice(searchStart));
      if (index == null) {
        // no nearest point found - keep track as is
        break;
      }
      index += searchStart;
      if (distance < 20) {
        if (deleteBetween) {
          track.removeRange(searchStart, index);
          searchStart += 1;
          deleteBetween = false;
        } else {
          searchStart = index + 1;
        }
      } else {
        track.insert(searchStart, markedPos);
        searchStart += 1;
        deleteBetween = true;
      }
    }
    if (deleteBetween) {
      track.removeRange(searchStart, track.length);
    }

    return track;
  }

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
            distance: track.isEmpty
                ? 0
                : track.last.distance + track.last.latLng.distanceTo(latLng),
            time: Duration.zero,
          ),
        );
      }
      final adjustedTrack = _adjustTrack(track, markedPositions);
      return Success(adjustedTrack);
    } else {
      _logger.i("mapbox api error ${response.error.runtimeType}");
      return Failure(RoutePlanningError.unknown);
    }
  }
}
