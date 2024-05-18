import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_api/mapbox_api.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/helpers/lat_lng.dart';

abstract class Defaults {
  static const sizedBox = _SizedBox();
  static const edgeInsets = _EdgeInsets();
  static final mapbox = _Mapbox();
  static final mapboxApi = MapboxApi(accessToken: Config.instance.accessToken);
  static final server = _Server();
  static final assets = _Assets();
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

class _Mapbox {
  _Mapbox();

  final trackLineColor = const Color.fromARGB(0xFF, 0xFF, 0, 0);
  final routeLineColor = const Color.fromARGB(0xFF, 0, 0, 0xFF);
  final cameraPosition = const LatLng(lat: 47.27, lng: 11.33);
}

class _Assets {
  _Assets();

  final beepLong = AssetSource('audio/beep_long.mp3'); // 0.99s
  final beepShort = AssetSource('audio/beep_short.mp3'); // 0.39s
  final beepMetronomeFile = 'assets/audio/beep_metronome.wav'; // 0.21s
}
