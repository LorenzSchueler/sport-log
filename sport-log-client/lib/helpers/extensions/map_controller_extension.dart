import 'dart:math';

import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Position;
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/lat_lng.dart';
import 'package:sport_log/helpers/pointer.dart';
import 'package:sport_log/models/cardio/position.dart';
import 'package:synchronized/synchronized.dart';

extension MapControllerExtension on MapboxMap {
  Future<LatLng> get center async =>
      LatLng.fromMap((await getCameraState()).center);

  Future<double> get zoom async => (await getCameraState()).zoom;

  Future<LatLngZoom> get latLngZoom async {
    final state = await getCameraState();
    return LatLngZoom(latLng: LatLng.fromMap(state.center), zoom: state.zoom);
  }

  // TODO diff to flyTo ??
  Future<void> animateCenter(LatLng center) =>
      easeTo(center.toCameraOptions(), null);

  Future<void> setZoom(double zoom) => flyTo(CameraOptions(zoom: zoom), null);

  Future<void> setNorth() => flyTo(CameraOptions(bearing: 0), null);

  Future<void> setBoundsX(LatLngBounds bounds, {required bool padded}) async {
    final paddedBounds = padded ? bounds.padded() : bounds;
    final center = paddedBounds.center;
    await setCamera(CameraOptions(center: center.toJsonPoint()));
    final screenCorner =
        await screenCoordToLatLng(ScreenCoordinate(x: 0, y: 0));
    final northwest = LatLng(
      lat: paddedBounds.northeast.lat,
      lng: paddedBounds.southwest.lng,
    );
    final latRatio =
        (center.lat - screenCorner.lat) / (center.lat - northwest.lat);
    final lngRatio =
        (center.lng - screenCorner.lng) / (center.lng - northwest.lng);
    final ratio = latRatio < lngRatio ? latRatio : lngRatio;
    final zoomAdd = log(ratio) / log(2);
    final cameraState = await getCameraState();
    await setCamera(CameraOptions(zoom: cameraState.zoom + zoomAdd));
  }

  Future<void> setBoundsFromTracks(
    Iterable<Position>? track1,
    Iterable<Position>? track2, {
    required bool padded,
  }) async {
    final bounds = LatLngBounds.combinedBounds(
      track1?.map((p) => p.latLng).latLngBounds,
      track2?.map((p) => p.latLng).latLngBounds,
    );
    if (bounds != null) {
      await setBoundsX(bounds, padded: padded);
    }
  }

  Future<LatLng> screenCoordToLatLng(
    ScreenCoordinate screenCoordinate,
  ) async =>
      LatLng.fromMap(await coordinateForPixel(screenCoordinate));
}

class LineManager {
  LineManager(this._manager);

  final PolylineAnnotationManager _manager;

  static final _lock = Lock();

  Future<PolylineAnnotation> addBoundingBoxLine(LatLngBounds bounds) async {
    return _manager.create(
      PolylineAnnotationOptions(
        geometry: bounds.toGeoJsonLineString(),
        lineWidth: 2,
        lineColor: Defaults.mapbox.trackLineColor,
      ),
    );
  }

  Future<void> updateBoundingBoxLine(
    NullablePointer<PolylineAnnotation> line,
    LatLngBounds? bounds,
  ) async {
    await _lock.synchronized(() async {
      if (line.isNull && bounds != null) {
        line.object = await addBoundingBoxLine(bounds);
      } else if (line.isNotNull && bounds != null) {
        line.object!.geometry = bounds.toGeoJsonLineString();
        await _manager.update(line.object!);
      } else if (line.isNotNull && bounds == null) {
        await _manager.delete(line.object!);
        line.setNull();
      }
    });
  }

  Future<PolylineAnnotation> addRouteLine(Iterable<Position> route) {
    return _manager.create(
      PolylineAnnotationOptions(
        geometry: route.map((p) => p.latLng).toGeoJsonLineString(),
        lineWidth: 2,
        lineColor: Defaults.mapbox.routeLineColor,
      ),
    );
  }

  Future<void> updateRouteLine(
    NullablePointer<PolylineAnnotation> line,
    Iterable<Position>? track,
  ) async {
    await _lock.synchronized(() async {
      if (line.isNull && track != null) {
        line.object = await addRouteLine(track);
      } else if (line.isNotNull && track != null) {
        line.object!.geometry =
            track.map((p) => p.latLng).toGeoJsonLineString();
        await _manager.update(line.object!);
      } else if (line.isNotNull && track == null) {
        await _manager.delete(line.object!);
        line.setNull();
      }
    });
  }

  Future<PolylineAnnotation> addTrackLine(Iterable<Position> track) {
    return _manager.create(
      PolylineAnnotationOptions(
        geometry: track.map((p) => p.latLng).toGeoJsonLineString(),
        lineWidth: 2,
        lineColor: Defaults.mapbox.trackLineColor,
      ),
    );
  }

  Future<void> updateTrackLine(
    NullablePointer<PolylineAnnotation> line,
    Iterable<Position>? track,
  ) async {
    await _lock.synchronized(() async {
      if (line.isNull && track != null) {
        line.object = await addTrackLine(track);
      } else if (line.isNotNull && track != null) {
        line.object!.geometry =
            track.map((p) => p.latLng).toGeoJsonLineString();
        await _manager.update(line.object!);
      } else if (line.isNotNull && track == null) {
        await _manager.delete(line.object!);
        line.setNull();
      }
    });
  }
}

class CircleManager {
  CircleManager(this._manager);

  final CircleAnnotationManager _manager;

  static final _lock = Lock();

  Future<List<CircleAnnotation>> addCurrentLocationMarker(
    LatLng latLng,
  ) async {
    return (await _manager.createMulti([
      CircleAnnotationOptions(
        geometry: latLng.toJsonPoint(),
        circleRadius: 8,
        circleColor: Defaults.mapbox.markerColor,
        circleOpacity: 0.5,
      ),
      CircleAnnotationOptions(
        geometry: latLng.toJsonPoint(),
        circleRadius: 20,
        circleColor: Defaults.mapbox.markerColor,
        circleOpacity: 0.3,
      ),
    ]))
        .cast<CircleAnnotation>();
  }

  Future<void> updateCurrentLocationMarker(
    NullablePointer<List<CircleAnnotation>> circles,
    LatLng? latLng,
  ) async {
    await _lock.synchronized(() async {
      if (circles.isNull && latLng != null) {
        circles.object = await addCurrentLocationMarker(latLng);
      } else if (circles.isNotNull && latLng != null) {
        circles.object = circles.object!
            .map((c) => c..geometry = latLng.toJsonPoint())
            .toList();
        for (final circle in circles.object!) {
          await _manager.update(circle);
        }
      } else if (circles.isNotNull && latLng == null) {
        for (final circle in circles.object!) {
          await _manager.delete(circle);
        }
        circles.setNull();
      }
    });
  }

  Future<CircleAnnotation> addLocationMarker(LatLng latLng) {
    return _manager.create(
      CircleAnnotationOptions(
        geometry: latLng.toJsonPoint(),
        circleRadius: 8,
        circleColor: Defaults.mapbox.markerColor,
        circleOpacity: 0.5,
      ),
    );
  }

  Future<void> removeLocationMarker(CircleAnnotation circle) =>
      _manager.delete(circle);

  Future<void> updateLocationMarker(
    NullablePointer<CircleAnnotation> circle,
    LatLng? latLng,
  ) async {
    await _lock.synchronized(() async {
      if (circle.isNull && latLng != null) {
        circle.object = await addLocationMarker(latLng);
      } else if (circle.isNotNull && latLng != null) {
        circle.object!.geometry = latLng.toJsonPoint();
        await _manager.update(circle.object!);
      } else if (circle.isNotNull && latLng == null) {
        await _manager.delete(circle.object!);
        circle.setNull();
      }
    });
  }

  Future<void> removeAll() => _manager.deleteAll();
}

class PointManager {
  PointManager(this._manager);

  final PointAnnotationManager _manager;

  Future<PointAnnotation> addLocationLabel(LatLng latLng, String label) {
    return _manager.create(
      PointAnnotationOptions(
        geometry: latLng.toJsonPoint(),
        textField: label,
        textOffset: [0, 1],
      ),
    );
  }

  Future<void> removeAll() => _manager.deleteAll();
}
