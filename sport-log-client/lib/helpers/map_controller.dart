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
    this.__controller,
    this.__lineManager,
    this.__circleManager,
    this.__pointManager,
  );

  static Future<MapController?> from(
    MapboxMap mapboxMap,
    BuildContext context,
  ) async {
    if (!context.mounted) {
      return null;
    }
    final lineManager =
        await mapboxMap.annotations.createPolylineAnnotationManager();
    if (!context.mounted) {
      return null;
    }
    final circleManager =
        await mapboxMap.annotations.createCircleAnnotationManager();
    if (!context.mounted) {
      return null;
    }
    final pointManager =
        await mapboxMap.annotations.createPointAnnotationManager();
    if (!context.mounted) {
      return null;
    }
    return MapController._(
      MountedWrapper(mapboxMap, context),
      MountedWrapper(lineManager, context),
      MountedWrapper(circleManager, context),
      MountedWrapper(pointManager, context),
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

  static const double _markerRadius = 8;
  static const double _gpsMarkerRadius = 20;
  static const double _noGpsMarkerRadius = 50;
  static const String _exaggerationProperty = "exaggeration";

  Future<LatLng?> get center async {
    final point = (await _controller?.getCameraState())?.center;
    if (point == null) {
      return null;
    }
    return LatLng.fromPoint(point);
  }

  Future<double?> get zoom async => (await _controller?.getCameraState())?.zoom;

  Future<LatLngZoom?> get latLngZoom async {
    final state = await _controller?.getCameraState();
    if (state == null) {
      return null;
    }
    return LatLngZoom(latLng: LatLng.fromPoint(state.center), zoom: state.zoom);
  }

  Future<double?> get pitch async =>
      (await _controller?.getCameraState())?.pitch;

  Future<void> _animatePitchBy(double pitch) async =>
      _controller?.pitchBy(pitch, null);

  Future<void> animateCenter(LatLng center) async =>
      await _controller?.flyTo(center.toCameraOptionsCenter(), null);

  Future<void> setCenter(LatLng center) async =>
      await _controller?.setCamera(center.toCameraOptionsCenter());

  Future<void> setZoom(double zoom) async =>
      await _controller?.setCamera(CameraOptions(zoom: zoom));

  Future<void> animateNorth() async =>
      await _controller?.flyTo(CameraOptions(bearing: 0), null);

  Future<void> setBoundsX(LatLngBounds bounds, {required bool padded}) async {
    final camera = await _controller?.cameraForCoordinatesPadding(
      [bounds.northeast.toPoint(), bounds.southwest.toPoint()],
      CameraOptions(),
      padded
          ? MbxEdgeInsets(top: 10, left: 10, bottom: 10, right: 10) // pixel
          : null,
      null,
      null,
    );
    if (camera != null) {
      await _controller?.setCamera(camera);
    }
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

  static int _floatToInt8(double x) {
    return (x * 255.0).round() & 0xff;
  }

  // alpha channel seems to be ignored
  int _colorToInt(Color color) =>
      (_floatToInt8(color.a) << 24) +
      (_floatToInt8(color.r) << 16) +
      (_floatToInt8(color.g) << 8) +
      _floatToInt8(color.b);

  Future<PolylineAnnotation?> addBoundingBoxLine(LatLngBounds bounds) async =>
      await _lineManager?.create(
        PolylineAnnotationOptions(
          geometry: bounds.toLineString(),
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
        line.object!.geometry = bounds.toLineString();
        await _lineManager?.update(line.object!);
      } else if (line.isNotNull && bounds == null) {
        await _lineManager?.delete(line.object!);
        line.setNull();
      }
    });
  }

  Future<PolylineAnnotation?> addLine(
    Iterable<Position> route,
    Color color, {
    double? lineOpacity,
  }) async => await _lineManager?.create(
    PolylineAnnotationOptions(
      geometry: route.map((p) => p.latLng).toLineString(),
      lineWidth: 2,
      lineColor: _colorToInt(color),
      lineOpacity: lineOpacity,
    ),
  );

  Future<void> updateLine(
    NullablePointer<PolylineAnnotation> line,
    Iterable<Position>? track,
    Color color, {
    double? lineOpacity,
  }) async {
    await _lock.synchronized(() async {
      if (line.isNull && track != null) {
        line.object = await addLine(track, color, lineOpacity: lineOpacity);
      } else if (line.isNotNull && track != null) {
        await removeLine(line.object!);
        line.object = await addLine(track, color, lineOpacity: lineOpacity);
        //line.object!.geometry = track.map((p) => p.latLng).toLineString();
        //line.object!.lineColor = _colorToInt(color);
        //line.object!.lineOpacity = lineOpacity;
        //await _lineManager?.update(line.object!);
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
  ) => updateLine(line, track, Defaults.mapbox.routeLineColor);

  Future<PolylineAnnotation?> addTrackLine(Iterable<Position> track) =>
      addLine(track, Defaults.mapbox.trackLineColor);

  Future<void> updateTrackLine(
    NullablePointer<PolylineAnnotation> line,
    Iterable<Position>? track, {
    double? lineOpacity,
  }) => updateLine(
    line,
    track,
    Defaults.mapbox.trackLineColor,
    lineOpacity: lineOpacity,
  );

  Future<List<CircleAnnotation>?> addCurrentLocationMarker(
    LatLng latLng,
    bool isGps,
  ) async {
    final color = _colorToInt(const Color.fromARGB(0xFF, 0, 0x60, 0xA0));
    return (await _circleManager?.createMulti([
      CircleAnnotationOptions(
        geometry: latLng.toPoint(),
        circleRadius: _markerRadius,
        circleColor: color,
        circleOpacity: 0.8,
      ),
      CircleAnnotationOptions(
        geometry: latLng.toPoint(),
        circleRadius: isGps ? _gpsMarkerRadius : _noGpsMarkerRadius,
        circleColor: color,
        circleOpacity: 0.4,
      ),
    ]))?.cast();
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
        circles.object =
            circles.object!.map((c) => c..geometry = latLng.toPoint()).toList();
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
          geometry: latLng.toPoint(),
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
        circle.object!.geometry = latLng.toPoint();
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
  ) => updateMarker(circle, latLng, Defaults.mapbox.trackLineColor);

  Future<void> updateRouteMarker(
    NullablePointer<CircleAnnotation> circle,
    LatLng? latLng,
  ) => updateMarker(circle, latLng, Defaults.mapbox.routeLineColor);

  Future<PointAnnotation?> addLabel(LatLng latLng, String label) async =>
      await _pointManager?.create(
        PointAnnotationOptions(
          geometry: latLng.toPoint(),
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

  Future<void> enableLayer(
    String sourceId,
    String sourceUrl,
    String layerId, {
    double? opacity,
    double? minZoom,
  }) async {
    if (!(await _sourceExists(sourceId) ?? true)) {
      await _addSource(RasterSource(id: sourceId, url: sourceUrl));
    }
    await _addLayer(
      RasterLayer(
        id: layerId,
        sourceId: sourceId,
        rasterOpacity: opacity,
        minZoom: minZoom,
      ),
    );
  }

  Future<void> disableLayer(String layerId) => _removeLayer(layerId);

  Future<bool> layerEnabled(String layerId) => _layerExists(layerId);

  Future<void> enableTerrain(String sourceId, double initPitch) async {
    await _addTerrainSource(sourceId);
    await _setStyleTerrainProperty("source", sourceId);
    await _setStyleTerrainProperty(_exaggerationProperty, 1);
    final currentPitch = await pitch;
    if (currentPitch != null) {
      await _animatePitchBy(initPitch - currentPitch);
    }
  }

  Future<void> disableTerrain() async {
    await _setStyleTerrainProperty(_exaggerationProperty, 0);
    final currentPitch = await pitch;
    if (currentPitch != null) {
      await _animatePitchBy(-currentPitch);
    }
  }

  Future<bool> terrainEnabled() async {
    final exaggeration = await _getStyleTerrainProperty(_exaggerationProperty);
    return exaggeration != null &&
        ![null, 0.0].contains(double.tryParse(exaggeration.toString()));
  }

  Future<bool?> _sourceExists(String sourceId) async =>
      await _controller?.style.styleSourceExists(sourceId);

  Future<void> _addSource(Source source) async =>
      await _controller?.style.addSource(source);

  Future<bool> _layerExists(String layerId) async =>
      await _controller?.style.styleLayerExists(layerId) ?? false;

  Future<void> _addLayer(Layer layer) async =>
      await _controller?.style.addLayer(layer);

  Future<void> _removeLayer(String layerId) async =>
      await _controller?.style.removeStyleLayer(layerId);

  Future<Object?> _getStyleTerrainProperty(String key) async =>
      (await _controller?.style.getStyleTerrainProperty(key))?.value;

  Future<void> _setStyleTerrainProperty(String key, Object value) async =>
      await _controller?.style.setStyleTerrainProperty(key, value);

  Future<void> styleAttribution() async => await _controller?.attribution
      .updateSettings(AttributionSettings(iconColor: 0x60000000));

  Future<void> hideAttribution() async => await _controller?.attribution
      .updateSettings(AttributionSettings(enabled: false));

  Future<void> hideLogo() async =>
      await _controller?.logo.updateSettings(LogoSettings(enabled: false));

  Future<void> hideCompass() async => await _controller?.compass.updateSettings(
    CompassSettings(enabled: false),
  );

  Future<void> showScaleBar() async =>
      await _controller?.scaleBar.updateSettings(
        ScaleBarSettings(
          enabled: true,
          position: OrnamentPosition.BOTTOM_RIGHT,
        ),
      );

  Future<void> setGestureSettings({
    required bool doubleTapZoomEnabled,
    required bool zoomEnabled,
    required bool rotateEnabled,
    required bool scrollEnabled,
    required bool pitchEnabled,
  }) async => await _controller?.gestures.updateSettings(
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
      elevation = await _controller?.getElevation(latLng.toPoint());
      if (elevation != null) {
        break;
      }
      // ignore: inference_failure_on_instance_creation
      await Future.delayed(Duration(milliseconds: 10 * pow(2, attempt) as int));
    }
    return elevation;
  }
}
