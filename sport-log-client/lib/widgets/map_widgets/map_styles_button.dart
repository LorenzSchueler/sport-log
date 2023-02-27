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

  Future<void> _addTerrainSource(
    MapController mapController,
    String sourceId,
  ) async {
    if (!(await mapController.sourceExists(sourceId) ?? true)) {
      await mapController.addSource(
        RasterDemSource(
          id: sourceId,
          url: 'mapbox://mapbox.mapbox-terrain-dem-v1',
        ),
      );
    }
  }
}

class _HillshadeOption extends _MapOption {
  const _HillshadeOption();

  static const _terrainSourceId = "mapbox-terrain-dem-v1-hillshade";
  static const _hillshadeLayerId = "hillshade-layer";

  @override
  Future<void> enable(MapController mapController) async {
    await super._addTerrainSource(mapController, _terrainSourceId);
    await mapController.addLayer(
      HillshadeLayer(
        id: _hillshadeLayerId,
        sourceId: _terrainSourceId,
        hillshadeShadowColor: 0x404040,
        hillshadeHighlightColor: 0x404040,
      ),
    );
  }

  @override
  Future<void> disable(MapController mapController) async {
    await mapController.removeLayer(_hillshadeLayerId);
  }
}

class _ThreeDOption extends _MapOption {
  const _ThreeDOption();

  static const _terrainSourceId = "mapbox-terrain-dem-v1-3d";
  static const _exaggeration = 1.0;
  static const _pitch = 60.0;

  @override
  Future<void> enable(MapController mapController) async {
    await super._addTerrainSource(mapController, _terrainSourceId);
    await mapController.setStyleTerrainProperty("source", _terrainSourceId);
    await mapController.setStyleTerrainProperty("exaggeration", _exaggeration);
    final currentPitch = await mapController.pitch;
    if (currentPitch != null) {
      await mapController.pitchBy(_pitch - currentPitch);
    }
  }

  @override
  Future<void> disable(MapController mapController) async {
    await mapController.setStyleTerrainProperty("exaggeration", "0");
    final currentPitch = await mapController.pitch;
    if (currentPitch != null) {
      await mapController.pitchBy(-currentPitch);
    }
  }
}

class _MapStylesBottomSheetState extends State<MapStylesBottomSheet> {
  Set<_MapOption> _options = {};
  String _style = MapboxStyles.OUTDOORS;

  final style = ButtonStyle(
    shape: MaterialStateProperty.all(const CircleBorder()),
    padding: MaterialStateProperty.all(const EdgeInsets.all(10)),
  );

  @override
  void initState() {
    _setCurrentState();
    super.initState();
  }

  Future<void> _setCurrentState() async {
    final style = await widget.mapController.getStyle();
    final hasHillshade = await widget.mapController
        .layerExists(_HillshadeOption._hillshadeLayerId);
    final exaggeration =
        await widget.mapController.getStyleTerrainProperty("exaggeration");
    if (style == null || hasHillshade == null || exaggeration == null) {
      return;
    }
    final isThreeD = ![null, 0.0].contains(double.tryParse(exaggeration));
    setState(() {
      _style = style;
      _options = {
        if (hasHillshade) const _HillshadeOption(),
        if (isThreeD) const _ThreeDOption()
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
            style: Theme.of(context).textTheme.bodyLarge,
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
                value: MapboxStyles.MAPBOX_STREETS,
                icon: Icon(AppIcons.car),
                label: Text("Street"),
              ),
              ButtonSegment(
                value: MapboxStyles.SATELLITE,
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
            style: Theme.of(context).textTheme.bodyLarge,
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
                value: _ThreeDOption(),
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
