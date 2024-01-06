import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Position;
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/lat_lng.dart';
import 'package:sport_log/helpers/mounted_wrapper.dart';
import 'package:sport_log/helpers/pointer.dart';
import 'package:sport_log/models/cardio/position.dart';
import 'package:synchronized/synchronized.dart';

const double _markerRadius = 8;
const double _gpsMarkerRadius = 20;
const double _noGpsMarkerRadius = 50;

class MapController {
  MapController._(
    this.__controller,
    this.__lineManager,
    this.__circleManager,
    this.__pointManager,
  );

  static Future<MapController?> from(
    MapboxMap mapboxMap,
    BuildContext context,
  ) async {
    final MountedWrapper<MapboxMap> controller;
    final MountedWrapper<PolylineAnnotationManager> lineManager;
    if (context.mounted) {
      controller = MountedWrapper(mapboxMap, context);
      lineManager = MountedWrapper(
        await mapboxMap.annotations.createPolylineAnnotationManager(),
        context,
      );
    } else {
      return null;
    }
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

  final MountedWrapper<MapboxMap> __controller;
  MapboxMap? get _controller => __controller.ifMounted;
  final MountedWrapper<PolylineAnnotationManager> __lineManager;
  PolylineAnnotationManager? get _lineManager => __lineManager.ifMounted;
  final MountedWrapper<CircleAnnotationManager> __circleManager;
  CircleAnnotationManager? get _circleManager => __circleManager.ifMounted;
  final MountedWrapper<PointAnnotationManager> __pointManager;
  PointAnnotationManager? get _pointManager => __pointManager.ifMounted;
  final _lock = Lock();

  Future<LatLng?> get center async {
    final latLngMap = (await _controller?.getCameraState())?.center;
    if (latLngMap == null) {
      return null;
    }
    return LatLng.fromMap(latLngMap);
  }

  Future<double?> get zoom async => (await _controller?.getCameraState())?.zoom;

  Future<LatLngZoom?> get latLngZoom async {
    final state = await _controller?.getCameraState();
    if (state == null) {
      return null;
    }
    return LatLngZoom(latLng: LatLng.fromMap(state.center), zoom: state.zoom);
  }

  Future<double?> get pitch async =>
      (await _controller?.getCameraState())?.pitch;

  Future<void> _animatePitchBy(double pitch) async =>
      _controller?.pitchBy(pitch, null);

  Future<LatLng?> _screenCoordToLatLng(
    ScreenCoordinate screenCoordinate,
  ) async {
    final latLngMap = await _controller?.coordinateForPixel(screenCoordinate);
    if (latLngMap == null) {
      return null;
    }
    return LatLng.fromMap(latLngMap);
  }

  Future<void> animateCenter(LatLng center) async =>
      await _controller?.flyTo(center.toCameraOptions(), null);

  Future<void> setCenter(LatLng center) async =>
      await _controller?.setCamera(center.toCameraOptions());

  Future<void> setZoom(double zoom) async =>
      await _controller?.setCamera(CameraOptions(zoom: zoom));

  Future<void> animateNorth() async =>
      await _controller?.flyTo(CameraOptions(bearing: 0), null);

  Future<void> setBoundsX(LatLngBounds bounds, {required bool padded}) async {
    final paddedBounds = padded ? bounds.padded() : bounds;
    final center = paddedBounds.center;
    if (_controller == null) {
      return;
    }
    await _controller?.setCamera(CameraOptions(center: center.toJsonPoint()));

    final screenCorner =
        await _screenCoordToLatLng(ScreenCoordinate(x: 0, y: 0));
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
    final cameraState = await _controller?.getCameraState();
    if (cameraState == null) {
      return;
    }
    await _controller
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

  // alpha channel seems to be ignored
  int _colorToInt(Color color) =>
      (color.alpha << 24) + (color.red << 16) + (color.green << 8) + color.blue;

  Future<PolylineAnnotation?> addBoundingBoxLine(LatLngBounds bounds) async =>
      await _lineManager?.create(
        PolylineAnnotationOptions(
          geometry: bounds.toGeoJsonLineString(),
          lineWidth: 2,
          lineColor: _colorToInt(Defaults.mapbox.trackLineColor),
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
        await _lineManager?.update(line.object!);
      } else if (line.isNotNull && bounds == null) {
        await _lineManager?.delete(line.object!);
        line.setNull();
      }
    });
  }

  Future<PolylineAnnotation?> addLine(
    Iterable<Position> route,
    Color color,
  ) async =>
      await _lineManager?.create(
        PolylineAnnotationOptions(
          geometry: route.map((p) => p.latLng).toGeoJsonLineString(),
          lineWidth: 2,
          lineColor: _colorToInt(color),
        ),
      );

  Future<void> updateLine(
    NullablePointer<PolylineAnnotation> line,
    Iterable<Position>? track,
    Color color,
  ) async {
    await _lock.synchronized(() async {
      if (line.isNull && track != null) {
        line.object = await addLine(track, color);
      } else if (line.isNotNull && track != null) {
        line.object!.geometry =
            track.map((p) => p.latLng).toGeoJsonLineString();
        await _lineManager?.update(line.object!);
      } else if (line.isNotNull && track == null) {
        await removeLine(line.object!);
        line.setNull();
      }
    });
  }

  Future<void> removeLine(PolylineAnnotation line) async =>
      await _lineManager?.delete(line);

  Future<PolylineAnnotation?> addRouteLine(Iterable<Position> route) =>
      addLine(route, Defaults.mapbox.routeLineColor);

  Future<void> updateRouteLine(
    NullablePointer<PolylineAnnotation> line,
    Iterable<Position>? track,
  ) =>
      updateLine(line, track, Defaults.mapbox.routeLineColor);

  Future<PolylineAnnotation?> addTrackLine(Iterable<Position> track) =>
      addLine(track, Defaults.mapbox.trackLineColor);

  Future<void> updateTrackLine(
    NullablePointer<PolylineAnnotation> line,
    Iterable<Position>? track,
  ) =>
      updateLine(line, track, Defaults.mapbox.trackLineColor);

  Future<List<CircleAnnotation>?> addCurrentLocationMarker(
    LatLng latLng,
    bool isGps,
  ) async {
    final color = _colorToInt(const Color.fromARGB(0xFF, 0, 0x60, 0xA0));
    return (await _circleManager?.createMulti([
      CircleAnnotationOptions(
        geometry: latLng.toJsonPoint(),
        circleRadius: _markerRadius,
        circleColor: color,
        circleOpacity: 0.5,
      ),
      CircleAnnotationOptions(
        geometry: latLng.toJsonPoint(),
        circleRadius: isGps ? _gpsMarkerRadius : _noGpsMarkerRadius,
        circleColor: color,
        circleOpacity: 0.3,
      ),
    ]))
        ?.cast();
  }

  Future<void> updateCurrentLocationMarker(
    NullablePointer<List<CircleAnnotation>> circles,
    LatLng? latLng,
    bool isGps,
  ) async {
    await _lock.synchronized(() async {
      if (circles.isNull && latLng != null) {
        circles.object = await addCurrentLocationMarker(latLng, isGps);
      } else if (circles.isNotNull && latLng != null) {
        circles.object = circles.object!
            .map((c) => c..geometry = latLng.toJsonPoint())
            .toList();
        circles.object![1].circleRadius =
            isGps ? _gpsMarkerRadius : _noGpsMarkerRadius;
        for (final circle in circles.object!) {
          await _circleManager?.update(circle);
        }
      } else if (circles.isNotNull && latLng == null) {
        for (final circle in circles.object!) {
          await _circleManager?.delete(circle);
        }
        circles.setNull();
      }
    });
  }

  Future<CircleAnnotation?> addMarker(LatLng latLng, Color color) async =>
      await _circleManager?.create(
        CircleAnnotationOptions(
          geometry: latLng.toJsonPoint(),
          circleRadius: _markerRadius,
          circleColor: _colorToInt(color),
          circleOpacity: 0.5,
        ),
      );

  Future<void> updateMarker(
    NullablePointer<CircleAnnotation> circle,
    LatLng? latLng,
    Color color,
  ) async {
    await _lock.synchronized(() async {
      if (circle.isNull && latLng != null) {
        circle.object = await addMarker(latLng, color);
      } else if (circle.isNotNull && latLng != null) {
        circle.object!.geometry = latLng.toJsonPoint();
        await _circleManager?.update(circle.object!);
      } else if (circle.isNotNull && latLng == null) {
        await _circleManager?.delete(circle.object!);
        circle.setNull();
      }
    });
  }

  Future<void> removeAllMarkers() async => await _circleManager?.deleteAll();

  Future<CircleAnnotation?> addTrackMarker(LatLng latLng) =>
      addMarker(latLng, Defaults.mapbox.trackLineColor);

  Future<CircleAnnotation?> addRouteMarker(LatLng latLng) =>
      addMarker(latLng, Defaults.mapbox.routeLineColor);

  Future<void> updateTrackMarker(
    NullablePointer<CircleAnnotation> circle,
    LatLng? latLng,
  ) =>
      updateMarker(circle, latLng, Defaults.mapbox.trackLineColor);

  Future<void> updateRouteMarker(
    NullablePointer<CircleAnnotation> circle,
    LatLng? latLng,
  ) =>
      updateMarker(circle, latLng, Defaults.mapbox.routeLineColor);

  Future<PointAnnotation?> addLabel(
    LatLng latLng,
    String label,
  ) async =>
      await _pointManager?.create(
        PointAnnotationOptions(
          geometry: latLng.toJsonPoint(),
          textField: label,
          textOffset: [0, 1],
        ),
      );

  Future<void> removeAllLabels() async => await _pointManager?.deleteAll();

  Future<void> setStyle(String styleUri) async =>
      await _controller?.style.setStyleURI(styleUri);

  Future<String?> getStyle() async => await _controller?.style.getStyleURI();

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

  Future<void> disableHillshade(String layerId) async {
    await _removeLayer(layerId);
    // this make removeLayer work more reliably but still the hillshade is sometimes not removed
    await setZoom((await zoom)!); // TODO remove if removeLayer works reliably
  }

  Future<bool?> hillshadeEnabled(String layerId) => _layerExists(layerId);

  Future<void> enableTerrain(String sourceId, double initPitch) async {
    await _addTerrainSource(sourceId);
    await _setStyleTerrainProperty("source", sourceId);
    await _setStyleTerrainProperty("exaggeration", 1);
    final currentPitch = await pitch;
    if (currentPitch != null) {
      await _animatePitchBy(initPitch - currentPitch);
    }
  }

  Future<void> disableTerrain() async {
    await _setStyleTerrainProperty("exaggeration", 0);
    final currentPitch = await pitch;
    if (currentPitch != null) {
      await _animatePitchBy(-currentPitch);
    }
  }

  Future<bool?> terrainEnabled() async {
    final exaggeration = await _getStyleTerrainProperty("exaggeration");
    if (exaggeration == null) {
      return null;
    }
    return ![null, 0.0].contains(double.tryParse(exaggeration.toString()));
  }

  Future<bool?> _sourceExists(String sourceId) async =>
      await _controller?.style.styleSourceExists(sourceId);

  Future<void> _addSource(Source source) async =>
      await _controller?.style.addSource(source);

  Future<bool?> _layerExists(String layerId) async =>
      await _controller?.style.styleLayerExists(layerId);

  Future<void> _addLayer(Layer layer) async =>
      await _controller?.style.addLayer(layer);

  Future<void> _removeLayer(String layerId) async =>
      await _controller?.style.removeStyleLayer(layerId);

  Future<Object?> _getStyleTerrainProperty(String key) async =>
      (await _controller?.style.getStyleTerrainProperty(key))?.value;

  Future<void> _setStyleTerrainProperty(String key, Object value) async =>
      await _controller?.style.setStyleTerrainProperty(key, value);

  Future<void> hideAttribution() async =>
      await _controller?.attribution.updateSettings(
        AttributionSettings(iconColor: 0x00000000, clickable: false),
      );

  Future<void> hideCompass() async => await _controller?.compass
      .updateSettings(CompassSettings(enabled: false));

  Future<void> setScaleBarSettings({
    OrnamentPosition position = OrnamentPosition.BOTTOM_RIGHT,
    bool enabled = true,
  }) async =>
      await _controller?.scaleBar.updateSettings(
        ScaleBarSettings(position: position, enabled: enabled),
      );

  Future<void> setGestureSettings({
    required bool doubleTapZoomEnabled,
    required bool zoomEnabled,
    required bool rotateEnabled,
    required bool scrollEnabled,
    required bool pitchEnabled,
  }) async =>
      await _controller?.gestures.updateSettings(
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
  MapboxMap? get _controller => _mapController._controller;

  Future<double?> getElevation(LatLng latLng) async {
    // setZoom = 15 & enableTerrain called in ElevationMap.onMapCreated
    if (_controller == null) {
      return null;
    }
    await _mapController.setCenter(latLng);
    double? elevation;
    for (var attempt = 0; attempt < 8; attempt++) {
      elevation = await _controller?.getElevation(latLng.toJsonPoint());
      if (elevation != null) {
        break;
      }
      // ignore: inference_failure_on_instance_creation
      await Future.delayed(
        Duration(milliseconds: 10 * pow(2, attempt) as int),
      );
    }
    return elevation;
  }
}
