import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:provider/provider.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/settings.dart';

class StaticMapboxMap extends StatelessWidget {
  const StaticMapboxMap({
    this.onMapCreated,
    this.onStyleLoadedCallback,
    this.onMapClick,
    this.onMapLongClick,
    super.key,
  });

  final void Function(MapboxMapController)? onMapCreated;
  final void Function()? onStyleLoadedCallback;
  final void Function(Point<double>, LatLng)? onMapClick;
  final void Function(Point<double>, LatLng)? onMapLongClick;

  @override
  Widget build(BuildContext context) {
    return MapboxMap(
      accessToken: Config.instance.accessToken,
      styleString: MapboxStyles.OUTDOORS,
      initialCameraPosition: context.read<Settings>().lastMapPosition,
      onMapCreated: onMapCreated?.call,
      onStyleLoadedCallback: onStyleLoadedCallback,
      onMapClick: onMapClick,
      onMapLongClick: onMapLongClick,
      rotateGesturesEnabled: false,
      scrollGesturesEnabled: false,
      zoomGesturesEnabled: false,
      tiltGesturesEnabled: false,
      doubleClickZoomEnabled: false,
      dragEnabled: false,
    );
  }
}
