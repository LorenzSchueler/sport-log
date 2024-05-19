import 'package:flutter/material.dart' hide Route;
import 'package:sport_log/data_provider/data_providers/cardio_data_provider.dart';
import 'package:sport_log/helpers/location_utils.dart';
import 'package:sport_log/models/cardio/position.dart';
import 'package:sport_log/models/cardio/route.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/provider_consumer.dart';

class AddLocationButton extends StatelessWidget {
  AddLocationButton({
    required this.route,
    required this.updateRoute,
    required this.locationUtils,
    super.key,
  });

  final Route route;
  final void Function(Route? route) updateRoute;
  final LocationUtils locationUtils;

  final _dataProvider = RouteDataProvider();

  Future<void> addLocationToRoute() async {
    final gpsPos = locationUtils.lastLocation;
    if (gpsPos == null) {
      return;
    }
    route.markedPositions ??= [];
    final pos = Position(
      latitude: gpsPos.latitude,
      longitude: gpsPos.longitude,
      elevation: gpsPos.elevation,
      distance: 0,
      time: Duration.zero,
    );
    route.markedPositions!.add(pos..distance = 0);
    route.track ??= [];
    final distance = route.track!.isEmpty
        ? 0.0
        : route.track!.last.distance +
            route.track!.last.latLng.distanceTo(gpsPos.latLng);
    route.track!.add(pos..distance = distance);
    route.setDistance();
    await _dataProvider.updateSingle(route);
    updateRoute(route);
  }

  @override
  Widget build(BuildContext context) {
    return ProviderConsumer.value(
      value: locationUtils,
      builder: (context, locationUtils, _) => FloatingActionButton.small(
        heroTag: null,
        onPressed:
            locationUtils.hasAccurateLocation ? addLocationToRoute : null,
        backgroundColor: locationUtils.hasAccurateLocation ? null : Colors.grey,
        child: const Icon(AppIcons.addLocation),
      ),
    );
  }
}
