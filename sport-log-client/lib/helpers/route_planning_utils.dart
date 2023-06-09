import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:mapbox_api/mapbox_api.dart';
import 'package:result_type/result_type.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/lat_lng.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/cardio/position.dart';
import 'package:sport_log/models/clone_extensions.dart';

enum SnapMode {
  alwaysSnap,
  snapIfClose,
  neverSnap;

  String get name => switch (this) {
        SnapMode.alwaysSnap => "Always Snap",
        SnapMode.snapIfClose => "Snap If Close",
        SnapMode.neverSnap => "Never Snap",
      };
}

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
  static const int _maxDistance = 20;

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
      if (distance < _maxDistance) {
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

  static List<Position> _setDistances(List<Position> track) {
    if (track.isNotEmpty) {
      track[0].distance = 0;
    }
    for (var i = 1; i < track.length; i++) {
      track[i].distance = track[i - 1].distance +
          track[i - 1].latLng.distanceTo(track[i].latLng);
    }
    return track;
  }

  static Future<List<Position>> _responseToTrack(
    DirectionsApiResponse response,
    Future<double?> Function(LatLng)? getElevation,
  ) async {
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
    return track;
  }

  static Future<Result<List<Position>, RoutePlanningError>> matchLocations(
    List<Position> markedPositions,
    SnapMode snapMode,
    Future<double?> Function(LatLng)? getElevation,
  ) async {
    if (snapMode == SnapMode.neverSnap) {
      var track = markedPositions.clone();
      track = _setDistances(track);
      return Success(track);
    }

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
      final track = await _responseToTrack(response, getElevation);
      if (snapMode == SnapMode.snapIfClose) {
        var adjustedTrack = _adjustTrack(track, markedPositions);
        adjustedTrack = _setDistances(track);
        return Success(adjustedTrack);
      } else {
        // snapMode == SnapMode.alwaysSnap
        return Success(track);
      }
    } else {
      _logger.i("mapbox api error ${response.error.runtimeType}");
      return Failure(RoutePlanningError.unknown);
    }
  }
}
