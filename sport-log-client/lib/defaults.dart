import 'package:flutter/material.dart';
import 'package:mapbox_api/mapbox_api.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:sport_log/config.dart';

abstract class Defaults {
  static const sizedBox = _SizedBox();
  static const edgeInsets = _EdgeInsets();
  static const borderRadius = _BorderRadius();
  static final mapbox = _Mapbox();
  static final mapboxApi = MapboxApi(accessToken: Config.instance.accessToken);
  static final server = _Server();
}

class _Server {
  _Server();

  final emulatorUrl = 'http://10.0.2.2:8000';
}

class _EdgeInsets {
  const _EdgeInsets();

  final normal = const EdgeInsets.all(10);
}

class _SizedBox {
  const _SizedBox();

  final horizontal = const _Horizontal();
  final vertical = const _Vertical();
}

class _Horizontal {
  const _Horizontal();

  final huge = const SizedBox(width: 40);
  final big = const SizedBox(width: 20);
  final normal = const SizedBox(width: 10);
  final small = const SizedBox(width: 5);
}

class _Vertical {
  const _Vertical();

  final huge = const SizedBox(height: 40);
  final big = const SizedBox(height: 20);
  final normal = const SizedBox(height: 10);
  final small = const SizedBox(height: 5);
}

class _BorderRadius {
  const _BorderRadius();

  final big = const BorderRadius.all(Radius.circular(20));
  final normal = const BorderRadius.all(Radius.circular(10));
  final small = const BorderRadius.all(Radius.circular(5));
}

class _Mapbox {
  _Mapbox();

  final style = const _Style();
  final markerColor = "#0060a0";
  final trackLineColor = "red";
  final routeLineColor = "blue";
  final cameraPosition = const LatLng(47.27, 11.33);
}

class _Style {
  const _Style();

  final String outdoor = "mapbox://styles/mapbox/outdoors-v11";
  final String street = "mapbox://styles/mapbox/streets-v11";
  final String satellite = "mapbox://styles/mapbox/satellite-v9";
}
