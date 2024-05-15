import 'package:flutter/material.dart' hide Visibility;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/map_controller.dart';
import 'package:sport_log/widgets/app_icons.dart';

class MapStylesButton extends StatelessWidget {
  const MapStylesButton({required this.mapController, super.key});

  final MapController mapController;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: null,
      child: const Icon(AppIcons.layers),
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        builder: (_) => MapStylesBottomSheet(mapController: mapController),
      ),
    );
  }
}

class MapStylesBottomSheet extends StatefulWidget {
  const MapStylesBottomSheet({required this.mapController, super.key});

  final MapController mapController;

  @override
  State<MapStylesBottomSheet> createState() => _MapStylesBottomSheetState();
}

abstract class _MapOption {
  const _MapOption();

  Future<void> enable(MapController mapController);

  Future<void> disable(MapController mapController);
}

class _HillshadeOption extends _MapOption {
  const _HillshadeOption();

  static const _terrainSourceId = "mapbox-terrain-dem-v1-hillshade";
  static const _hillshadeLayerId = "hillshade-layer";

  @override
  Future<void> enable(MapController mapController) =>
      mapController.enableHillshade(_terrainSourceId, _hillshadeLayerId);

  @override
  Future<void> disable(MapController mapController) =>
      mapController.disableHillshade(_hillshadeLayerId);
}

class _TerrainOption extends _MapOption {
  const _TerrainOption();

  static const _terrainSourceId = "mapbox-terrain-dem-v1-3d";
  static const _pitch = 60.0;

  @override
  Future<void> enable(MapController mapController) =>
      mapController.enableTerrain(_terrainSourceId, _pitch);

  @override
  Future<void> disable(MapController mapController) =>
      mapController.disableTerrain();
}

class _MapStylesBottomSheetState extends State<MapStylesBottomSheet> {
  Set<_MapOption> _options = {};
  String _style = MapboxStyles.OUTDOORS;

  // based on mapbox SATELLITE_STREETS
  // road network - surface: road-street
  //     opacity: 0.5
  // road network - surface: road-minor
  //     color: hsl(35, 80%, 48%)
  //     opacity: 1
  //     width: 2
  //     dash-array: 5, 2
  // road network - surface: road-minor-case
  //     color: hsl(35, 80%, 0%)
  // walking, cycling, etc - surface - road-path
  //     color: hsl(35, 80%, 48%)
  //     opacity: 1
  //     width: 2
  //     dash-array: 2, 1
  static const String satelliteStreetsWithPaths =
      "mapbox://styles/hi-ker/cloa9i53h011s01qsdf867pcy";

  final style = ButtonStyle(
    shape: WidgetStateProperty.all(const CircleBorder()),
    padding: WidgetStateProperty.all(const EdgeInsets.all(10)),
  );

  @override
  void initState() {
    _setCurrentState();
    super.initState();
  }

  Future<void> _setCurrentState() async {
    final style = await widget.mapController.getStyle();
    final hasHillshade = await widget.mapController
        .hillshadeEnabled(_HillshadeOption._hillshadeLayerId);
    final hasTerrain = await widget.mapController.terrainEnabled();
    if (style == null) {
      return;
    }
    setState(() {
      _style = style;
      _options = {
        if (hasHillshade) const _HillshadeOption(),
        if (hasTerrain) const _TerrainOption(),
      };
    });
  }

  Future<void> _setStyle(Set<String> style) async {
    await _setOptions({}); // disable all options
    await widget.mapController.setStyle(style.first);
    setState(() => _style = style.first);
  }

  Future<void> _setOptions(Set<_MapOption> options) async {
    for (final option in _options.difference(options)) {
      await option.disable(widget.mapController);
    }
    for (final option in options.difference(_options)) {
      await option.enable(widget.mapController);
    }
    setState(() => _options = options);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: Defaults.edgeInsets.normal,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Map Type",
            style: Theme.of(context).textTheme.labelLarge,
          ),
          Defaults.sizedBox.vertical.small,
          SegmentedButton(
            segments: const [
              ButtonSegment(
                value: MapboxStyles.OUTDOORS,
                icon: Icon(AppIcons.mountains),
                label: Text("Outdoor"),
              ),
              ButtonSegment(
                value: MapboxStyles.STANDARD,
                icon: Icon(AppIcons.car),
                label: Text("Street"),
              ),
              ButtonSegment(
                value: satelliteStreetsWithPaths,
                icon: Icon(AppIcons.satellite),
                label: Text("Satellite"),
              ),
            ],
            selected: {_style},
            onSelectionChanged: _setStyle,
            showSelectedIcon: false,
          ),
          Defaults.sizedBox.vertical.small,
          const Divider(),
          Text(
            "Map Options",
            style: Theme.of(context).textTheme.labelLarge,
          ),
          Defaults.sizedBox.vertical.small,
          SegmentedButton(
            segments: const [
              ButtonSegment(
                value: _HillshadeOption(),
                icon: Icon(AppIcons.invertColors),
                label: Text("Hillshade"),
              ),
              ButtonSegment(
                value: _TerrainOption(),
                icon: Icon(AppIcons.threeD),
                label: Text("3D"),
              ),
            ],
            multiSelectionEnabled: true,
            emptySelectionAllowed: true,
            selected: _options,
            onSelectionChanged: _setOptions,
            showSelectedIcon: false,
          ),
        ],
      ),
    );
  }
}
