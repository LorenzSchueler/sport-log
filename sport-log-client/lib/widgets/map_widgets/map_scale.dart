import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

class MapScale extends StatefulWidget {
  const MapScale({required this.mapController, super.key});

  final MapboxMapController mapController;

  @override
  State<MapScale> createState() => _MapScaleState();
}

class _MapScaleState extends State<MapScale> {
  static const _maxWidth = 200;

  double _width = 0;
  int _scaleLength = 1;

  @override
  void initState() {
    widget.mapController.addListener(_mapControllerListener);
    super.initState();
  }

  @override
  void dispose() {
    widget.mapController.removeListener(_mapControllerListener);
    super.dispose();
  }

  Future<void> _mapControllerListener() async {
    final latitude = widget.mapController.cameraPosition!.target.latitude;
    final metersPerPixel =
        await widget.mapController.getMetersPerPixelAtLatitude(latitude);
    if (mounted) {
      setState(() {
        _width = _calcWidth(metersPerPixel);
        _scaleLength = _calcScaleLength(metersPerPixel);
      });
    }
  }

  double _calcWidth(double metersPerPixel) {
    final maxWidthMeters = _maxWidth * metersPerPixel;
    final fac = maxWidthMeters / pow(10, (log(maxWidthMeters) / ln10).floor());
    if (fac >= 1 && fac < 2) {
      return _maxWidth / fac;
    } else if (fac < 5) {
      return _maxWidth / fac * 2;
    } else {
      // fac < 10
      return _maxWidth / fac * 5;
    }
  }

  int _calcScaleLength(double metersPerPixel) {
    return (_width * metersPerPixel).round();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _width,
      color: Theme.of(context).colorScheme.background,
      child: Text(
        _scaleLength >= 1000
            ? "${(_scaleLength / 1000).round()} km"
            : "$_scaleLength m",
        textAlign: TextAlign.center,
      ),
    );
  }
}
