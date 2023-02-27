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

  Future<void> _addTerrainSource(MapController mapController) async {
    if (!(await mapController.sourceExists(_terrainSourceId) ?? true)) {
      await mapController.addSource(
        RasterDemSource(
          id: _terrainSourceId,
          url: 'mapbox://mapbox.mapbox-terrain-dem-v1',
        ),
      );
    }
  }

  @override
  Future<void> enable(MapController mapController) async {
    await _addTerrainSource(mapController);
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

  Future<void> _addTerrainSource(MapController mapController) async {
    if (!(await mapController.sourceExists(_terrainSourceId) ?? true)) {
      await mapController.addSource(
        RasterDemSource(
          id: _terrainSourceId,
          url: 'mapbox://mapbox.mapbox-terrain-dem-v1',
        ),
      );
    }
  }

  @override
  Future<void> enable(MapController mapController) async {
    await _addTerrainSource(mapController);
    await mapController.setStyleTerrainProperty("source", _terrainSourceId);
    await mapController.setStyleTerrainProperty("exaggeration", _exaggeration);
    await mapController.pitchBy(_pitch);
  }

  @override
  Future<void> disable(MapController mapController) async {
    await mapController.setStyleTerrainProperty("exaggeration", "0");
    // while exaggeration is 0 this does not matter but it is needed so that setting it back to 60 works
    final pitch = await mapController.pitch;
    if (pitch != null) {
      await mapController.pitchBy(-pitch);
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
    final hasThreeD = ![null, 0.0].contains(double.tryParse(exaggeration));
    setState(() {
      _style = style;
      _options = {
        if (hasHillshade) const _HillshadeOption(),
        if (hasThreeD) const _ThreeDOption()
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
          SegmentedButton(
            segments: const [
              ButtonSegment(
                value: MapboxStyles.OUTDOORS,
                icon: Icon(AppIcons.mountains),
              ),
              ButtonSegment(
                value: MapboxStyles.MAPBOX_STREETS,
                icon: Icon(AppIcons.car),
              ),
              ButtonSegment(
                value: MapboxStyles.SATELLITE,
                icon: Icon(AppIcons.satellite),
              ),
            ],
            selected: {_style},
            onSelectionChanged: _setStyle,
            showSelectedIcon: false,
          ),
          Defaults.sizedBox.vertical.normal,
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
