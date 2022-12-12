import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/lat_lng_extension.dart';
import 'package:sport_log/helpers/pointer.dart';
import 'package:sport_log/models/cardio/position.dart';
import 'package:synchronized/synchronized.dart';

extension MapControllerExtension on MapboxMapController {
  static final _lock = Lock();

  Future<void> setNorth() => animateCamera(CameraUpdate.bearingTo(0));

  Future<void> setBounds(LatLngBounds bounds, {required bool padded}) {
    if (padded) {
      bounds = bounds.padded();
    }
    return moveCamera(CameraUpdate.newLatLngBounds(bounds));
  }

  Future<void> animateBounds(LatLngBounds bounds, {required bool padded}) {
    if (padded) {
      bounds = bounds.padded();
    }
    return animateCamera(CameraUpdate.newLatLngBounds(bounds));
  }

  Future<void> setBoundsFromTracks(
    List<Position>? track1,
    List<Position>? track2, {
    required bool padded,
  }) async {
    final bounds = LatLngBoundsCombine.combinedBounds(
      track1?.latLngBounds,
      track2?.latLngBounds,
    );
    if (bounds != null) {
      await setBounds(bounds, padded: padded);
    }
  }

  Future<void> animateCenter(LatLng center) =>
      animateCamera(CameraUpdate.newLatLng(center));

  Future<void> animateZoom(double zoom) =>
      animateCamera(CameraUpdate.zoomTo(zoom));

  Future<Line> addBoundingBoxLine(LatLng point1, LatLng point2) {
    return addLine(
      LineOptions(
        lineColor: Defaults.mapbox.trackLineColor,
        lineWidth: 2,
        geometry: [
          LatLng(point1.latitude, point1.longitude),
          LatLng(point1.latitude, point2.longitude),
          LatLng(point2.latitude, point2.longitude),
          LatLng(point2.latitude, point1.longitude),
          LatLng(point1.latitude, point1.longitude)
        ],
      ),
    );
  }

  Future<void> updateBoundingBoxLine(
    NullablePointer<Line> line,
    LatLng? point1,
    LatLng? point2,
  ) async {
    await _lock.synchronized(() async {
      if (line.isNotNull) {
        await removeLine(line.object!);
        line.setNull();
      }
      if (point1 != null && point2 != null) {
        line.object = await addBoundingBoxLine(point1, point2);
      }
    });
  }

  Future<Line> addRouteLine(List<Position> track) {
    return addLine(
      LineOptions(
        lineColor: Defaults.mapbox.routeLineColor,
        lineWidth: 2,
        geometry: track.latLngs,
      ),
    );
  }

  Future<void> updateRouteLine(
    NullablePointer<Line> line,
    List<Position>? track,
  ) async {
    await _lock.synchronized(() async {
      if (line.isNotNull) {
        await removeLine(line.object!);
        line.setNull();
      }
      if (track != null) {
        line.object = await addRouteLine(track);
      }
    });
  }

  Future<Line> addTrackLine(List<Position> track) {
    return addLine(
      LineOptions(
        lineColor: Defaults.mapbox.trackLineColor,
        lineWidth: 2,
        geometry: track.latLngs,
      ),
    );
  }

  Future<void> updateTrackLine(
    NullablePointer<Line> line,
    List<Position>? track,
  ) async {
    await _lock.synchronized(() async {
      if (line.isNotNull) {
        await removeLine(line.object!);
        line.setNull();
      }
      if (track != null) {
        line.object = await addTrackLine(track);
      }
    });
  }

  Future<List<Circle>> addCurrentLocationMarker(LatLng latLng) {
    return addCircles([
      CircleOptions(
        circleRadius: 8.0,
        circleColor: Defaults.mapbox.markerColor,
        circleOpacity: 0.5,
        geometry: latLng,
      ),
      CircleOptions(
        circleRadius: 20.0,
        circleColor: Defaults.mapbox.markerColor,
        circleOpacity: 0.3,
        geometry: latLng,
      ),
    ]);
  }

  Future<void> updateCurrentLocationMarker(
    NullablePointer<List<Circle>> circles,
    LatLng? latLng,
  ) async {
    await _lock.synchronized(() async {
      if (circles.isNotNull) {
        await removeCircles(circles.object!);
        circles.setNull();
      }
      if (latLng != null) {
        circles.object = await addCurrentLocationMarker(latLng);
      }
    });
  }

  Future<Circle> addLocationMarker(LatLng latLng) {
    return addCircle(
      CircleOptions(
        circleRadius: 8.0,
        circleColor: Defaults.mapbox.markerColor,
        circleOpacity: 0.5,
        geometry: latLng,
      ),
    );
  }

  Future<void> updateLocationMarker(
    NullablePointer<Circle> circle,
    LatLng? latLng,
  ) async {
    await _lock.synchronized(() async {
      if (circle.isNotNull) {
        await removeCircle(circle.object!);
        circle.setNull();
      }
      if (latLng != null) {
        circle.object = await addLocationMarker(latLng);
      }
    });
  }
}
