import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:mapbox_api_pro/mapbox_api_pro.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/lat_lng.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/result.dart';
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
        // since position matching to last markedPos there is no point within max distance to current markedPos
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

  static Future<void> _setDistanceAndElevation(
    List<Position> track,
    Future<double?> Function(LatLng)? getElevation,
  ) async {
    if (track.isNotEmpty) {
      track[0].distance = 0;
      track[0].elevation = (await getElevation?.call(track[0].latLng)) ?? 0;
    }
    for (var i = 1; i < track.length; i++) {
      track[i].distance =
          track[i - 1].distance +
          track[i - 1].latLng.distanceTo(track[i].latLng);
      track[i].elevation =
          (await getElevation?.call(track[i].latLng)) ?? track[i - 1].elevation;
    }
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
      await _setDistanceAndElevation(track, getElevation);
      return Ok(track);
    }

    final latLngs = <LatLng>[];
    const maxChunkLen = 25;
    final chunks = ((markedPositions.length - 1) / (maxChunkLen - 1)).ceil();
    for (var chunk = 0; chunk < chunks; chunk++) {
      final start = chunk * (maxChunkLen - 1);
      final markedPositionsChunk = markedPositions.slice(
        start,
        min(start + 25, markedPositions.length),
      );
      logDebug(markedPositionsChunk.length);

      DirectionsApiResponse response;
      try {
        response = await Defaults.mapboxApi.directions.request(
          profile: NavigationProfile.WALKING,
          overview: NavigationOverview.FULL,
          coordinates: markedPositionsChunk
              .map((e) => [e.latitude, e.longitude])
              .toList(),
        );
      } on SocketException {
        return Err(RoutePlanningError.noInternet);
      }

      final geometry = response.routes?.elementAtOrNull(0)?.geometry;
      if (geometry != null) {
        var chunkLatLngs = _decodePolyline(geometry as String).slice(0);
        if (chunk > 0 && chunkLatLngs.first == latLngs.last) {
          chunkLatLngs = chunkLatLngs.slice(1);
        }
        latLngs.addAll(chunkLatLngs);
      } else {
        final responseError = response.error;
        final error = responseError == null
            ? "geometry is null"
            : responseError is NavigationError
            ? responseError.message
            : responseError.toString();

        logDebug(error);

        _logger.e(
          "mapbox api error",
          error: error,
          caughtBy: "RoutePlanningUtils.matchLocations",
        );
        return Err(RoutePlanningError.mapboxApiError);
      }
    }

    final track = latLngs
        .map(
          (latLng) => Position(
            latitude: latLng.lat,
            longitude: latLng.lng,
            elevation: 0,
            distance: 0,
            time: Duration.zero,
          ),
        )
        .toList();

    if (snapMode == SnapMode.snapIfClose) {
      _snapIfClose(track, markedPositions);
    }
    // for SnapMode.alwaysSnap nothing to do

    await _setDistanceAndElevation(track, getElevation);
    return Ok(track);
  }
}
