import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart' hide Route;
import 'package:sport_log/data_provider/data_providers/cardio_data_provider.dart';
import 'package:sport_log/helpers/location_utils.dart';
import 'package:sport_log/models/cardio/position.dart';
import 'package:sport_log/models/cardio/route.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/dialogs.dart';
import 'package:sport_log/widgets/provider_consumer.dart';

class AddLocationButton extends StatefulWidget {
  const AddLocationButton({
    required this.route,
    required this.updateRoute,
    required this.locationUtils,
    super.key,
  });

  final Route route;
  final void Function(Route? route) updateRoute;
  final LocationUtils locationUtils;

  @override
  State<AddLocationButton> createState() => _AddLocationButtonState();
}

class _AddLocationButtonState extends State<AddLocationButton> {
  final _dataProvider = RouteDataProvider();

  // the route is only replaced once the update succeeded, so a second position
  // added in the meantime would be based on the route without the first one
  bool _isAdding = false;

  Future<void> addLocationToRoute() async {
    final gpsPos = widget.locationUtils.lastLocation;
    if (gpsPos == null) {
      return;
    }
    setState(() => _isAdding = true);
    try {
      // work on a clone so that a failed update does not change the shown route
      final updatedRoute = widget.route.clone()
        ..markedPositions ??= []
        ..track ??= [];
      final pos = Position(
        latitude: gpsPos.latitude,
        longitude: gpsPos.longitude,
        elevation: gpsPos.elevation,
        distance: 0,
        time: Duration.zero,
      );
      final lastPos = updatedRoute.track!.lastOrNull;
      updatedRoute.markedPositions!.add(pos);
      // separate instance so that the distance within the track does not also
      // apply to the marked position
      updatedRoute.track!.add(
        pos.clone()
          ..distance = lastPos == null
              ? 0
              : lastPos.distance + lastPos.latLng.distanceTo(gpsPos.latLng),
      );
      updatedRoute.setDistance();
      final result = await _dataProvider.updateSingle(updatedRoute);
      if (result.isErr) {
        if (mounted) {
          await showMessageDialog(
            context: context,
            title: "Adding Location Failed",
            text: result.err.toString(),
          );
        }
        return;
      }
      widget.updateRoute(updatedRoute);
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProviderConsumer.value(
      value: widget.locationUtils,
      builder: (context, locationUtils, _) {
        final enabled = locationUtils.hasAccurateLocation && !_isAdding;
        return FloatingActionButton.small(
          heroTag: null,
          onPressed: enabled ? addLocationToRoute : null,
          backgroundColor: enabled ? null : Colors.grey,
          child: const Icon(AppIcons.addLocation),
        );
      },
    );
  }
}
