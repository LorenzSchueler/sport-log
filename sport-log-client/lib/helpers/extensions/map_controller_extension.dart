import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/models/cardio/position.dart';

extension MapControllerExtension on MapboxMapController {
  Future<void> setNorth() => animateCamera(CameraUpdate.bearingTo(0));

  Future<void> setBounds(LatLngBounds bounds) =>
      moveCamera(CameraUpdate.newLatLngBounds(bounds));

  Future<void> animateBounds(LatLngBounds bounds) =>
      animateCamera(CameraUpdate.newLatLngBounds(bounds));

  Future<void> setBoundsFromTracks(
    List<Position>? track1,
    List<Position>? track2,
  ) async {
    final bounds = LatLngBoundsCombine.combinedBounds(track1, track2);
    if (bounds != null) {
      await setBounds(bounds);
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

  Future<Line> addRouteLine(List<Position> track) {
    return addLine(
      LineOptions(
        lineColor: Defaults.mapbox.routeLineColor,
        lineWidth: 2,
        geometry: track.latLngs,
      ),
    );
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

  Future<void> updateTrackLine(Line line, List<Position> track) async {
    await updateLine(
      line,
      LineOptions(geometry: track.latLngs),
    );
  }

  Future<List<Circle>> addCurrentLocationMarker(LatLng latLng) {
    return addCircles([
      CircleOptions(
        circleRadius: 8.0,
        circleColor: Defaults.mapbox.markerColor,
        circleOpacity: 0.5,
        geometry: latLng,
        draggable: false,
      ),
      CircleOptions(
        circleRadius: 20.0,
        circleColor: Defaults.mapbox.markerColor,
        circleOpacity: 0.3,
        geometry: latLng,
        draggable: false,
      ),
    ]);
  }

  Future<List<Circle>> updateCurrentLocationMarker(
    List<Circle> circles,
    LatLng latLng,
  ) async {
    await removeCircles(circles);
    return await addCurrentLocationMarker(latLng);
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
}
