import 'dart:math';

import 'package:flutter/material.dart';

class MapScale extends StatelessWidget {
  const MapScale({required this.metersPerPixel, super.key});

  final double metersPerPixel;

  double get _scaleWidth {
    const maxWidth = 200;
    final maxWidthMeters = maxWidth * metersPerPixel;
    final fac = maxWidthMeters / pow(10, (log(maxWidthMeters) / ln10).floor());
    if (fac >= 1 && fac < 2) {
      return maxWidth / fac;
    } else if (fac < 5) {
      return maxWidth / fac * 2;
    } else {
      // fac < 10
      return maxWidth / fac * 5;
    }
  }

  int get _scaleLength {
    return (_scaleWidth * metersPerPixel).round();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _scaleWidth,
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
