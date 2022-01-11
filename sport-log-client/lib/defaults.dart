import 'package:flutter/material.dart';

abstract class Defaults {
  static const sizedBox = _SizedBox();
  static const borderRadius = _BorderRadius();
  static const mapbox = _Mapbox();
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

  final style = const _Style();
}

class _Style {
  const _Style();

  final String outdoor = 'mapbox://styles/mapbox/outdoors-v11';
}
