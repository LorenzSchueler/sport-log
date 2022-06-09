import 'package:flutter/material.dart' hide Route;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:provider/provider.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/data_provider/data_providers/cardio_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/map_controller_extension.dart';
import 'package:sport_log/helpers/gpx.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/validation.dart';
import 'package:sport_log/models/cardio/position.dart';
import 'package:sport_log/models/cardio/route.dart';
import 'package:sport_log/pages/workout/cardio/route_value_unit_description_table.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/theme.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/message_dialog.dart';
import 'package:sport_log/widgets/pop_scopes.dart';

class RouteUploadPage extends StatefulWidget {
  const RouteUploadPage({Key? key}) : super(key: key);

  @override
  State<RouteUploadPage> createState() => _RouteUploadPageState();
}

class _RouteUploadPageState extends State<RouteUploadPage> {
  final _logger = Logger('RouteUploadPage');
  final _formKey = GlobalKey<FormState>();
  final _dataProvider = RouteDataProvider();

  Line? _line;

  late MapboxMapController _mapController;

  late Route _route;

  @override
  void initState() {
    _route = Route.defaultValue();
    _route.track ??= [];
    super.initState();
  }

  Future<void> _saveRoute() async {
    _logger.i("saving route");
    final result = await _dataProvider.createSingle(_route);
    if (result.isSuccess()) {
      _formKey.currentState!.deactivate();
      if (mounted) {
        Navigator.pop(context);
      }
    } else {
      await showMessageDialog(
        context: context,
        text: 'Creating Route Entry failed:\n${result.failure}',
      );
    }
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
                      _route.isValid()
                  ? _saveRoute
                  : null,
              icon: const Icon(AppIcons.save),
            )
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: MapboxMap(
                accessToken: Config.instance.accessToken,
                styleString: MapboxStyles.OUTDOORS,
                initialCameraPosition: context.read<Settings>().lastMapPosition,
                trackCameraPosition: true,
                compassEnabled: true,
                compassViewPosition: CompassViewPosition.TopRight,
                onMapCreated: (MapboxMapController controller) async {
                  _mapController = controller;
                },
                onStyleLoadedCallback: () async {
                  await _mapController.setBoundsFromTracks(
                    _route.track,
                    _route.markedPositions,
                    padded: true,
                  );
                  _line ??= await _mapController.addRouteLine([]);
                },
              ),
            ),
            Padding(
              padding: Defaults.edgeInsets.normal,
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
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
                      decoration:
                          Theme.of(context).textFormFieldDecoration.copyWith(
                                labelText: "Name",
                              ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _loadFile() async {
    final track = await loadTrackFromGpxFile();
    if (track == null) {
      await showMessageDialog(
        context: context,
        title: "An Error occured",
        text: "Parsing file failed.",
      );
    } else {
      setState(() {
        _route
          ..track = track
          ..setDistance()
          ..setAscentDescent();
      });
      await _mapController.updateLine(
        _line!,
        LineOptions(
          lineWidth: 2,
          geometry: _route.track?.latLngs,
        ),
      );
    }
  }
}
