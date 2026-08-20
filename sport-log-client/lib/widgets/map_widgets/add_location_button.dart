import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart' hide Route;
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
    route
      ..markedPositions ??= []
      ..track ??= [];
    final pos = Position(
      latitude: gpsPos.latitude,
      longitude: gpsPos.longitude,
      elevation: gpsPos.elevation,
      distance: 0,
      time: Duration.zero,
    );
    final lastPos = route.track!.lastOrNull;
    route.markedPositions!.add(pos);
    // separate instance so that the distance within the track does not also
    // apply to the marked position
    route.track!.add(
      pos.clone()
        ..distance = lastPos == null
            ? 0
            : lastPos.distance + lastPos.latLng.distanceTo(gpsPos.latLng),
    );
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
        onPressed: locationUtils.hasAccurateLocation
            ? addLocationToRoute
            : null,
        backgroundColor: locationUtils.hasAccurateLocation ? null : Colors.grey,
        child: const Icon(AppIcons.addLocation),
      ),
    );
  }
}
