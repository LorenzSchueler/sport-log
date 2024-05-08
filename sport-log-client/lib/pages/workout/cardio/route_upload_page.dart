import 'package:flutter/material.dart' hide Route;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:sport_log/data_provider/data_providers/cardio_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/gpx.dart';
import 'package:sport_log/helpers/map_controller.dart';
import 'package:sport_log/helpers/pointer.dart';
import 'package:sport_log/helpers/validation.dart';
import 'package:sport_log/models/cardio/route.dart';
import 'package:sport_log/pages/workout/cardio/route_value_unit_description_table.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/dialogs.dart';
import 'package:sport_log/widgets/map_widgets/mapbox_map_wrapper.dart';
import 'package:sport_log/widgets/pop_scopes.dart';

class RouteUploadPage extends StatefulWidget {
  const RouteUploadPage({super.key});

  @override
  State<RouteUploadPage> createState() => _RouteUploadPageState();
}

class _RouteUploadPageState extends State<RouteUploadPage> {
  final _formKey = GlobalKey<FormState>();
  final _dataProvider = RouteDataProvider();

  MapController? _mapController;

  final NullablePointer<PolylineAnnotation> _line =
      NullablePointer.nullPointer();

  late final Route _route = Route.defaultValue()..track = [];

  Future<void> _saveRoute() async {
    final result = await _dataProvider.createSingle(_route);
    if (mounted) {
      if (result.isOk) {
        Navigator.pop(context);
      } else {
        await showMessageDialog(
          context: context,
          title: "Creating Route Failed",
          text: result.err.toString(),
        );
      }
    }
  }

  Future<void> _onMapCreated(MapController mapController) async {
    _mapController = mapController;
    await _mapController?.setBoundsFromTracks(
      _route.track,
      _route.markedPositions,
      padded: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DiscardWarningOnPop(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Create Route"),
          actions: [
            IconButton(
              onPressed: _formKey.currentContext != null &&
                      _formKey.currentState!.validate() &&
                      _route.isValidBeforeSanitation()
                  ? _saveRoute
                  : null,
              icon: const Icon(AppIcons.save),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: MapboxMapWrapper(
                showFullscreenButton: false,
                showMapStylesButton: true,
                showSelectRouteButton: false,
                showSetNorthButton: true,
                showCurrentLocationButton: false,
                showCenterLocationButton: false,
                showAddLocationButton: false,
                onMapCreated: _onMapCreated,
              ),
            ),
            Padding(
              padding: Defaults.edgeInsets.normal,
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loadFile,
                      child: const Text("Open GPX File"),
                    ),
                  ),
                  Defaults.sizedBox.vertical.normal,
                  RouteValueUnitDescriptionTable(route: _route),
                  Defaults.sizedBox.vertical.normal,
                  Form(
                    key: _formKey,
                    child: TextFormField(
                      onChanged: (name) => setState(() => _route.name = name),
                      initialValue: _route.name,
                      validator: Validator.validateStringNotEmpty,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: const InputDecoration(
                        icon: Icon(AppIcons.route),
                        labelText: "Name",
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadFile() async {
    final track = await loadTrackFromGpxFile();
    if (mounted && track != null) {
      if (track.isErr) {
        await showMessageDialog(
          context: context,
          title: "An Error Occurred",
          text: track.err,
        );
      } else {
        setState(() {
          _route
            ..track = track.ok
            ..setDistance()
            ..setAscentDescent();
        });
        await _mapController?.setBoundsFromTracks(
          _route.track,
          _route.markedPositions,
          padded: true,
        );
        await _mapController?.updateRouteLine(_line, _route.track);
      }
    }
  }
}
