import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

abstract class Defaults {
  static const sizedBox = _SizedBox();
  static const borderRadius = _BorderRadius();
  static const mapbox = _Mapbox();
  static const server = _Server();
}

class _Server {
  const _Server();

  static const _defaultUrl = "127.0.0.1";
  final emulatorUrl = 'http://10.0.2.2:8000';
  final url = "http://" +
      const String.fromEnvironment('SERVER_ADDRESS', defaultValue: _defaultUrl);
}

class _SizedBox {
  const _SizedBox();

  final horizontal = const _Horizontal();
  final vertical = const _Vertical();
}

class _Horizontal {
  const _Horizontal();

  final huge = const SizedBox(
    width: 40,
  );
  final big = const SizedBox(
    width: 20,
  );
  final normal = const SizedBox(
    width: 10,
  );
  final small = const SizedBox(
    width: 5,
  );
}

class _Vertical {
  const _Vertical();

  final huge = const SizedBox(
    height: 40,
  );
  final big = const SizedBox(
    height: 20,
  );
  final normal = const SizedBox(
    height: 10,
  );
  final small = const SizedBox(
    height: 5,
  );
}

class _BorderRadius {
  const _BorderRadius();

  final big = const BorderRadius.all(Radius.circular(20));
  final normal = const BorderRadius.all(Radius.circular(10));
  final small = const BorderRadius.all(Radius.circular(5));
}

class _Mapbox {
  const _Mapbox();

  static String? _accessToken;
  String get accessToken {
    if (_accessToken == null) {
      String token = const String.fromEnvironment("ACCESS_TOKEN");
      if (token.isEmpty) {
        throw Exception(
          "please supply mapbox access token using --dart-define ACCESS_TOKEN=<token>",
        );
      }
      _accessToken = token;
    }
    return _accessToken!;
  }

  final style = const _Style();
  final markerColor = "#0060a0";
  final cameraPosition = const LatLng(47.27, 11.33);
}

class _Style {
  const _Style();

  final String outdoor = "mapbox://styles/mapbox/outdoors-v11";
  final String street = "mapbox://styles/mapbox/streets-v11";
  final String satellite = "mapbox://styles/mapbox/satellite-v9";
}
