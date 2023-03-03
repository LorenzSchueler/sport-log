import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Position;
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/lat_lng.dart';
import 'package:sport_log/helpers/mounted_wrapper.dart';
import 'package:sport_log/helpers/pointer.dart';
import 'package:sport_log/models/cardio/position.dart';
import 'package:synchronized/synchronized.dart';

class MapController {
  MapController._(
    this._controller,
    this._lineManager,
    this._circleManager,
    this._pointManager,
  );

  static Future<MapController?> from(
    MapboxMap mapboxMap,
    BuildContext context,
  ) async {
    final controller = MountedWrapper(mapboxMap, context);
    final lineManager = MountedWrapper(
      await mapboxMap.annotations.createPolylineAnnotationManager(),
      context,
    );
    final MountedWrapper<CircleAnnotationManager> circleManager;
    if (context.mounted) {
      circleManager = MountedWrapper(
        await mapboxMap.annotations.createCircleAnnotationManager(),
        context,
      );
    } else {
      return null;
    }
    final MountedWrapper<PointAnnotationManager> pointManager;
    if (context.mounted) {
      pointManager = MountedWrapper(
        await mapboxMap.annotations.createPointAnnotationManager(),
        context,
      );
    } else {
      return null;
    }
    return MapController._(
      controller,
      lineManager,
      circleManager,
      pointManager,
    );
  }

  final MountedWrapper<MapboxMap> _controller;
  final MountedWrapper<PolylineAnnotationManager> _lineManager;
  final MountedWrapper<CircleAnnotationManager> _circleManager;
  final MountedWrapper<PointAnnotationManager> _pointManager;
  final _lock = Lock();

  Future<LatLng?> get center async {
    final latLngMap = (await _controller.ifMounted?.getCameraState())?.center;
    if (latLngMap == null) {
      return null;
    }
    return LatLng.fromMap(latLngMap);
  }

  Future<double?> get zoom async =>
      (await _controller.ifMounted?.getCameraState())?.zoom;

  Future<LatLngZoom?> get latLngZoom async {
    final state = await _controller.ifMounted?.getCameraState();
    if (state == null) {
      return null;
    }
    return LatLngZoom(latLng: LatLng.fromMap(state.center), zoom: state.zoom);
  }

  Future<double?> get pitch async =>
      (await _controller.ifMounted?.getCameraState())?.pitch;

  Future<void> pitchBy(double pitch) async =>
      _controller.ifMounted?.pitchBy(pitch, null);

  Future<LatLng?> screenCoordToLatLng(
    ScreenCoordinate screenCoordinate,
  ) async {
    final latLngMap =
        await _controller.ifMounted?.coordinateForPixel(screenCoordinate);
    if (latLngMap == null) {
      return null;
    }
    return LatLng.fromMap(latLngMap);
  }

  // TODO diff to flyTo
  Future<void> animateCenter(LatLng center) async =>
      await _controller.ifMounted?.easeTo(center.toCameraOptions(), null);

  Future<void> setCenter(LatLng center) async =>
      await _controller.ifMounted?.setCamera(center.toCameraOptions());

  Future<void> setZoom(double zoom) async =>
      await _controller.ifMounted?.flyTo(CameraOptions(zoom: zoom), null);

  Future<void> setNorth() async =>
      await _controller.ifMounted?.flyTo(CameraOptions(bearing: 0), null);

  Future<void> setBoundsX(LatLngBounds bounds, {required bool padded}) async {
    final paddedBounds = padded ? bounds.padded() : bounds;
    final center = paddedBounds.center;
    if (_controller.ifMounted == null) {
      return;
    }
    await _controller.ifMounted
        ?.setCamera(CameraOptions(center: center.toJsonPoint()));

    final screenCorner =
        await screenCoordToLatLng(ScreenCoordinate(x: 0, y: 0));
    if (screenCorner == null) {
      return;
    }
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
    final cameraState = await _controller.ifMounted?.getCameraState();
    if (cameraState == null) {
      return;
    }
    await _controller.ifMounted
        ?.setCamera(CameraOptions(zoom: cameraState.zoom + zoomAdd));
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

  Future<PolylineAnnotation?> addBoundingBoxLine(LatLngBounds bounds) async =>
      await _lineManager.ifMounted?.create(
        PolylineAnnotationOptions(
          geometry: bounds.toGeoJsonLineString(),
          lineWidth: 2,
          lineColor: Defaults.mapbox.trackLineColor,
        ),
      );

  Future<void> updateBoundingBoxLine(
    NullablePointer<PolylineAnnotation> line,
    LatLngBounds? bounds,
  ) async {
    await _lock.synchronized(() async {
      if (line.isNull && bounds != null) {
        line.object = await addBoundingBoxLine(bounds);
      } else if (line.isNotNull && bounds != null) {
        line.object!.geometry = bounds.toGeoJsonLineString();
        await _lineManager.ifMounted?.update(line.object!);
      } else if (line.isNotNull && bounds == null) {
        await _lineManager.ifMounted?.delete(line.object!);
        line.setNull();
      }
    });
  }

  Future<PolylineAnnotation?> addRouteLine(Iterable<Position> route) async =>
      await _lineManager.ifMounted?.create(
        PolylineAnnotationOptions(
          geometry: route.map((p) => p.latLng).toGeoJsonLineString(),
          lineWidth: 2,
          lineColor: Defaults.mapbox.routeLineColor,
        ),
      );

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
        await _lineManager.ifMounted?.update(line.object!);
      } else if (line.isNotNull && track == null) {
        await _lineManager.ifMounted?.delete(line.object!);
        line.setNull();
      }
    });
  }

  Future<PolylineAnnotation?> addTrackLine(Iterable<Position> track) async =>
      await _lineManager.ifMounted?.create(
        PolylineAnnotationOptions(
          geometry: track.map((p) => p.latLng).toGeoJsonLineString(),
          lineWidth: 2,
          lineColor: Defaults.mapbox.trackLineColor,
        ),
      );

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
        await _lineManager.ifMounted?.update(line.object!);
      } else if (line.isNotNull && track == null) {
        await _lineManager.ifMounted?.delete(line.object!);
        line.setNull();
      }
    });
  }

  Future<List<CircleAnnotation>?> addCurrentLocationMarker(
    LatLng latLng,
  ) async {
    return (await _circleManager.ifMounted?.createMulti([
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
        ?.cast();
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
          await _circleManager.ifMounted?.update(circle);
        }
      } else if (circles.isNotNull && latLng == null) {
        for (final circle in circles.object!) {
          await _circleManager.ifMounted?.delete(circle);
        }
        circles.setNull();
      }
    });
  }

  Future<CircleAnnotation?> addLocationMarker(LatLng latLng) async =>
      await _circleManager.ifMounted?.create(
        CircleAnnotationOptions(
          geometry: latLng.toJsonPoint(),
          circleRadius: 8,
          circleColor: Defaults.mapbox.markerColor,
          circleOpacity: 0.5,
        ),
      );

  Future<void> removeLocationMarker(CircleAnnotation circle) async =>
      await _circleManager.ifMounted?.delete(circle);

  Future<void> updateLocationMarker(
    NullablePointer<CircleAnnotation> circle,
    LatLng? latLng,
  ) async {
    await _lock.synchronized(() async {
      if (circle.isNull && latLng != null) {
        circle.object = await addLocationMarker(latLng);
      } else if (circle.isNotNull && latLng != null) {
        circle.object!.geometry = latLng.toJsonPoint();
        await _circleManager.ifMounted?.update(circle.object!);
      } else if (circle.isNotNull && latLng == null) {
        await _circleManager.ifMounted?.delete(circle.object!);
        circle.setNull();
      }
    });
  }

  Future<void> removeAllCircles() async =>
      await _circleManager.ifMounted?.deleteAll();

  Future<PointAnnotation?> addLocationLabel(
    LatLng latLng,
    String label,
  ) async =>
      await _pointManager.ifMounted?.create(
        PointAnnotationOptions(
          geometry: latLng.toJsonPoint(),
          textField: label,
          textOffset: [0, 1],
        ),
      );

  Future<void> removeAllPoints() async =>
      await _pointManager.ifMounted?.deleteAll();

  Future<void> setStyle(String styleUri) async =>
      await _controller.ifMounted?.style.setStyleURI(styleUri);

  Future<String?> getStyle() async =>
      await _controller.ifMounted?.style.getStyleURI();

  Future<void> _addTerrainSource(String sourceId) async {
    if (!(await _sourceExists(sourceId) ?? true)) {
      await _addSource(
        RasterDemSource(
          id: sourceId,
          url: 'mapbox://mapbox.mapbox-terrain-dem-v1',
        ),
      );
    }
  }

  Future<void> enableHillshade(String sourceId, String layerId) async {
    await _addTerrainSource(sourceId);
    await _addLayer(
      HillshadeLayer(
        id: layerId,
        sourceId: sourceId,
        hillshadeShadowColor: 0x404040,
        hillshadeHighlightColor: 0x404040,
      ),
    );
  }

  Future<void> disableHillshade(String layerId) => _removeLayer(layerId);

  Future<bool?> hillshadeEnabled(String layerId) => _layerExists(layerId);

  Future<void> enableTerrain(String sourceId, double initPitch) async {
    await _addTerrainSource(sourceId);
    await _setStyleTerrainProperty("source", sourceId);
    await _setStyleTerrainProperty("exaggeration", 1);
    final currentPitch = await pitch;
    if (currentPitch != null) {
      await pitchBy(initPitch - currentPitch);
    }
  }

  Future<void> disableTerrain() async {
    await _setStyleTerrainProperty("exaggeration", 0);
    final currentPitch = await pitch;
    if (currentPitch != null) {
      await pitchBy(-currentPitch);
    }
  }

  Future<bool?> terrainEnabled() async {
    final exaggeration = await _getStyleTerrainProperty("exaggeration");
    if (exaggeration == null) {
      return null;
    }
    return ![null, 0.0].contains(double.tryParse(exaggeration));
  }

  Future<bool?> _sourceExists(String sourceId) async =>
      await _controller.ifMounted?.style.styleSourceExists(sourceId);

  Future<void> _addSource(Source source) async =>
      await _controller.ifMounted?.style.addSource(source);

  Future<bool?> _layerExists(String layerId) async =>
      await _controller.ifMounted?.style.styleLayerExists(layerId);

  Future<void> _addLayer(Layer layer) async =>
      await _controller.ifMounted?.style.addLayer(layer);

  Future<void> _removeLayer(String layerId) async =>
      await _controller.ifMounted?.style.removeStyleLayer(layerId);

  Future<String?> _getStyleTerrainProperty(String key) async =>
      (await _controller.ifMounted?.style.getStyleTerrainProperty(key))?.value;

  Future<void> _setStyleTerrainProperty(String key, Object value) async =>
      await _controller.ifMounted?.style.setStyleTerrainProperty(key, value);

  Future<void> hideAttribution() async =>
      await _controller.ifMounted?.attribution.updateSettings(
        AttributionSettings(iconColor: 0x00000000, clickable: false),
      );

  Future<void> hideCompass() async => await _controller.ifMounted?.compass
      .updateSettings(CompassSettings(enabled: false));

  Future<void> setScaleBarSettings({
    OrnamentPosition position = OrnamentPosition.BOTTOM_RIGHT,
    bool enabled = true,
  }) async =>
      await _controller.ifMounted?.scaleBar.updateSettings(
        ScaleBarSettings(position: position, enabled: enabled),
      );

  Future<void> setGestureSettings({
    required bool doubleTapZoomEnabled,
    required bool zoomEnabled,
    required bool rotateEnabled,
    required bool scrollEnabled,
    required bool pitchEnabled,
  }) async =>
      await _controller.ifMounted?.gestures.updateSettings(
        GesturesSettings(
          doubleTapToZoomInEnabled: doubleTapZoomEnabled,
          doubleTouchToZoomOutEnabled: false,
          rotateEnabled: rotateEnabled,
          scrollEnabled: scrollEnabled,
          pitchEnabled: pitchEnabled,
          pinchToZoomEnabled: zoomEnabled,
          quickZoomEnabled: false,
          pinchPanEnabled: false,
          simultaneousRotateAndPinchToZoomEnabled: rotateEnabled && zoomEnabled,
        ),
      );

  Future<void> disableAllGestures() => setGestureSettings(
        doubleTapZoomEnabled: false,
        rotateEnabled: false,
        scrollEnabled: false,
        pitchEnabled: false,
        zoomEnabled: false,
      );
}

class ElevationMapController {
  const ElevationMapController(this._mapController);

  final MapController _mapController;

  Future<double?> getElevation(LatLng latLng) async {
    await _mapController.setCenter(latLng);
    await _mapController.setZoom(15);
    await _mapController.enableTerrain("elevation-terrain-source", 0);
    return _mapController._controller.ifMounted
        ?.getElevation(latLng.toJsonPoint());
  }
}
