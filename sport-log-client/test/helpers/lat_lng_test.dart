import 'package:flutter_test/flutter_test.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:sport_log/helpers/lat_lng.dart';

/// Points along the equator, 0.001° (~111 m) apart.
List<LatLng> _track(List<int> steps) => [
  for (final s in steps) LatLng(lat: 0, lng: s / 1000),
];

void main() {
  const latLng = LatLng(lat: 47.5, lng: 11.25);
  const bounds = LatLngBounds(north: 48, south: 47, east: 12, west: 11);

  test("fromPoint reads lat and lng from the coordinates", () {
    expect(LatLng.fromPoint(Point(coordinates: Position(11.25, 47.5))), latLng);
  });

  test("toPoint puts lng before lat in the coordinates", () {
    expect(latLng.toPoint(), Point(coordinates: Position(11.25, 47.5)));
  });

  test("toCameraOptionsCenter centers the camera on the point", () {
    expect(latLng.toCameraOptionsCenter().center, latLng.toPoint());
  });

  group("==", () {
    final cases = {
      "holds with the same hashCode for the same lat and lng": (
        other: const LatLng(lat: 47.5, lng: 11.25),
        equal: true,
      ),
      "fails for another lat": (
        other: const LatLng(lat: 47, lng: 11.25),
        equal: false,
      ),
      "fails for another lng": (
        other: const LatLng(lat: 47.5, lng: 11),
        equal: false,
      ),
    };

    for (final MapEntry(key: name, value: (:other, :equal)) in cases.entries) {
      test(name, () {
        expect(latLng == other, equal);
        if (equal) expect(latLng.hashCode, other.hashCode);
      });
    }
  });

  group("toString", () {
    final cases = {
      "uses N and O for north and east": (
        latLng: latLng,
        expected: "47°30.000'N 11°15.000'O",
      ),
      "uses S and W for south and west": (
        latLng: const LatLng(lat: -0.5, lng: -11.25),
        expected: "0°30.000'S 11°15.000'W",
      ),
    };

    for (final MapEntry(key: name, value: (:latLng, :expected))
        in cases.entries) {
      test(name, () {
        expect(latLng.toString(), expected);
      });
    }
  });

  test("distanceTo returns the geodesic distance in meters", () {
    expect(
      const LatLng(lat: 0, lng: 0).distanceTo(const LatLng(lat: 1, lng: 0)),
      closeTo(110574, 1),
    );
  });

  group("minDistanceTo", () {
    final cases = {
      "returns infinity and no index for an empty track": (
        track: <LatLng>[],
        distance: equals(double.infinity),
        index: null,
      ),
      "returns the distance to and index of the closest point": (
        track: _track([3, 1, 2]),
        distance: closeTo(111.19, 0.01),
        index: 1,
      ),
    };

    for (final MapEntry(key: name, value: (:track, :distance, :index))
        in cases.entries) {
      test(name, () {
        final (d, i) = const LatLng(lat: 0, lng: 0).minDistanceTo(track);
        expect(d, distance);
        expect(i, index);
      });
    }
  });

  group("similarTo", () {
    final track = _track([0, 1, 2, 3]);
    final cases = {
      "is true for the same track": (other: track, similar: true),
      "is true for a track shifted by ~11 m": (
        other: [for (final p in track) LatLng(lat: 0.0001, lng: p.lng)],
        similar: true,
      ),
      "is false for an empty track": (other: <LatLng>[], similar: false),
      "is false for another start": (other: _track([1, 2, 3]), similar: false),
      "is false for another end": (other: _track([0, 1, 2]), similar: false),
      "is false for a missing middle point": (
        other: _track([0, 1, 3]),
        similar: false,
      ),
      "is false for middle points in another order": (
        other: _track([0, 2, 1, 3]),
        similar: false,
      ),
    };

    for (final MapEntry(key: name, value: (:other, :similar))
        in cases.entries) {
      test(name, () {
        expect(track.similarTo(other), similar);
        expect(other.similarTo(track), similar);
      });
    }
  });

  group("latLngBounds", () {
    final cases = {
      "is null for no points": (points: <LatLng>[], expected: null),
      "collapses to a single point": (
        points: [const LatLng(lat: 47, lng: 11)],
        expected: [47.0, 11.0, 47.0, 11.0],
      ),
      "spans the outermost lat and lng of multiple points": (
        points: [
          const LatLng(lat: 47.5, lng: 12),
          const LatLng(lat: 48, lng: 11.5),
          const LatLng(lat: 47, lng: 11),
        ],
        expected: [48.0, 12.0, 47.0, 11.0],
      ),
    };

    for (final MapEntry(key: name, value: (:points, :expected))
        in cases.entries) {
      test(name, () {
        expect(points.latLngBounds?.toList(), expected);
      });
    }
  });

  test("Iterable.toLineString keeps the points in order", () {
    expect(_track([0, 1]).toLineString().coordinates, [
      Position(0, 0),
      Position(0.001, 0),
    ]);
  });

  test("LatLngZoom.toCameraOptions sets center and zoom", () {
    final options = const LatLngZoom(
      latLng: latLng,
      zoom: 10,
    ).toCameraOptions();
    expect(options.center, latLng.toPoint());
    expect(options.zoom, 10);
  });

  test("fromList reads [north, east, south, west]", () {
    final b = LatLngBounds.fromList([48, 12, 47, 11]);
    expect([b.north, b.east, b.south, b.west], [48.0, 12.0, 47.0, 11.0]);
  });

  group("combinedBounds", () {
    const other = LatLngBounds(north: 49, south: 47.5, east: 11.5, west: 10);
    final cases = {
      "is null when both are null": (b1: null, b2: null, expected: null),
      "is the second when the first is null": (
        b1: null,
        b2: bounds,
        expected: bounds.toList(),
      ),
      "is the first when the second is null": (
        b1: bounds,
        b2: null,
        expected: bounds.toList(),
      ),
      "spans both when both are set": (
        b1: bounds,
        b2: other,
        expected: [49.0, 12.0, 47.0, 10.0],
      ),
    };

    for (final MapEntry(key: name, value: (:b1, :b2, :expected))
        in cases.entries) {
      test(name, () {
        expect(LatLngBounds.combinedBounds(b1, b2)?.toList(), expected);
      });
    }
  });

  test("toPolygon lists the corners counterclockwise from northeast", () {
    expect(bounds.toPolygon().coordinates, [
      [Position(12, 48), Position(11, 48), Position(11, 47), Position(12, 47)],
    ]);
  });

  test("toList returns [north, east, south, west]", () {
    expect(bounds.toList(), [48.0, 12.0, 47.0, 11.0]);
  });

  test("LatLngBounds.toLineString traces the corners back to northeast", () {
    expect(bounds.toLineString().coordinates, [
      Position(12, 48),
      Position(11, 48),
      Position(11, 47),
      Position(12, 47),
      Position(12, 48),
    ]);
  });

  test("center lies midway between the edges", () {
    expect(bounds.center, const LatLng(lat: 47.5, lng: 11.5));
  });
}
