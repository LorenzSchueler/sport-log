import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:mapbox_api/mapbox_api.dart';
import 'package:result_type/result_type.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/lat_lng.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/cardio/position.dart';
import 'package:sport_log/models/clone_extensions.dart';

enum SnapMode {
  alwaysSnap("Always Snap"),
  snapIfClose("Snap If Close"),
  neverSnap("Never Snap");

  const SnapMode(this.name);

  final String name;
}

enum RoutePlanningError {
  noInternet("No Internet Connection"),
  mapboxApiError("Mapbox API Error");

  const RoutePlanningError(this.message);

  final String message;
}

class RoutePlanningUtils {
  static const int _maxDistance = 20;

  static final _logger = Logger("RoutePlanningUtils");

  // Remove parts that are too far from the marked points and replace them with straight line.
  static void _snapIfClose(
    List<Position> track,
    List<Position> markedPositions,
  ) {
    var searchStart = 0;
    var deleteBetween = false;
    for (final markedPos in markedPositions) {
      var (distance, index) = markedPos.minDistanceTo(track.slice(searchStart));
      if (index == null) {
        // track is empty
        break;
      }
      index += searchStart;
      if (distance < _maxDistance) {
        if (deleteBetween) {
          // the last markedPos had no matching point but this one has
          // create straight line to current matching point by removing everything in between
          track.removeRange(searchStart, index);
          searchStart += 1;
          deleteBetween = false;
        } else {
          // the last markedPos and the current one have both a matching points so just advance the search window
          searchStart = index + 1;
        }
      } else {
        // since position matching to last markedPos there is no point withing max distance to current markedPos
        // insert markedPos and start delete window
        track.insert(searchStart, markedPos);
        searchStart += 1;
        deleteBetween = true;
      }
    }
    if (deleteBetween) {
      track.removeRange(searchStart, track.length);
    }
  }

  static void _setDistances(List<Position> track) {
    if (track.isNotEmpty) {
      track[0].distance = 0;
    }
    for (var i = 1; i < track.length; i++) {
      track[i].distance = track[i - 1].distance +
          track[i - 1].latLng.distanceTo(track[i].latLng);
    }
  }

  static Future<List<Position>> _responseToTrack(
    DirectionsApiResponse response,
    Future<double?> Function(LatLng)? getElevation,
  ) async {
    final navRoute = response.routes![0];
    final track = <Position>[];
    final latLngs = _decodePolyline(navRoute.geometry as String);
    for (final latLng in latLngs) {
      final elevation = (await getElevation?.call(latLng)) ??
          track.lastOrNull?.elevation ??
          0;
      track.add(
        Position(
          latitude: latLng.lat,
          longitude: latLng.lng,
          elevation: elevation,
          distance: track.isEmpty
              ? 0
              : track.last.distance + track.last.latLng.distanceTo(latLng),
          time: Duration.zero,
        ),
      );
    }
    return track;
  }

  // https://developers.google.com/maps/documentation/utilities/polylinealgorithm
  static List<LatLng> _decodePolyline(
    String polyline, {
    int accuracyExponent = 5,
  }) {
    final accuracyMultiplier = pow(10, accuracyExponent);
    final latLngs = <LatLng>[];

    var index = 0;
    var lat = 0;
    var lng = 0;

    while (index < polyline.length) {
      // Return difference to next value (latitude or longitude)
      int getNextDiff() {
        var shift = 0;
        var value = 0;
        int byte, chunk;

        // Iterating while value is grater or equal of `32-bits` size
        do {
          // convert char to int
          byte = polyline.codeUnitAt(index++);
          // subtract 63
          byte -= 63;
          // AND byte with 0x1f to undo OR with 0x20
          chunk = byte & 0x1f;
          // add next 5 bits chunks to value
          value |= chunk << shift;
          shift += 5;
          // check if another byte follows (byte & 0x20 > 0)
        } while (byte >= 0x20);

        // right-shift value by one bit
        // invert value if negative
        return (value & 1) != 0
            ? (~BigInt.from(value >> 1)).toInt()
            : value >> 1;
      }

      lat += getNextDiff();
      lng += getNextDiff();

      latLngs.add(
        LatLng(lat: lat / accuracyMultiplier, lng: lng / accuracyMultiplier),
      );
    }

    return latLngs;
  }

  static Future<Result<List<Position>, RoutePlanningError>> matchLocations(
    List<Position> markedPositions,
    SnapMode snapMode,
    Future<double?> Function(LatLng)? getElevation,
  ) async {
    if (snapMode == SnapMode.neverSnap) {
      final track = markedPositions.clone();
      _setDistances(track);
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
        _snapIfClose(track, markedPositions);
        _setDistances(track);
        return Success(track);
      } else {
        // snapMode == SnapMode.alwaysSnap
        return Success(track);
      }
    } else {
      _logger.e(
        "mapbox api error",
        error: response.error,
        caughtBy: "RoutePlanningUtils.matchLocations",
      );
      return Failure(RoutePlanningError.mapboxApiError);
    }
  }
}
