import 'package:flutter/material.dart' hide Visibility;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/widgets/app_icons.dart';

class MapStylesButton extends StatelessWidget {
  const MapStylesButton({required this.mapController, super.key});

  final MapboxMap mapController;

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

  final MapboxMap mapController;

  @override
  State<MapStylesBottomSheet> createState() => _MapStylesBottomSheetState();
}

class _MapStylesBottomSheetState extends State<MapStylesBottomSheet> {
  bool _hillshade = false;
  // ignore: non_constant_identifier_names
  bool _3D = false;

  static const _terrainSourceId = "mapbox-terrain-dem-v1";
  static const _hillshadeLayerId = "custom-hillshade";
  static const _exaggeration = 1.0;
  static const _pitch = 60.0;

  final style = ButtonStyle(
    shape: MaterialStateProperty.all(const CircleBorder()),
    padding: MaterialStateProperty.all(const EdgeInsets.all(10)),
  );

  @override
  void initState() {
    _setOptionState();
    super.initState();
  }

  Future<void> _setOptionState() async {
    _hillshade =
        await widget.mapController.style.styleLayerExists(_hillshadeLayerId);
    _3D = double.tryParse(
          (await widget.mapController.style
                  .getStyleTerrainProperty("exaggeration"))
              .value,
        ) ==
        _exaggeration;
    setState(() {});
  }

  Future<void> _addTerrainSource() async {
    if (!await widget.mapController.style.styleSourceExists(_terrainSourceId)) {
      await widget.mapController.style.addSource(
        RasterDemSource(
          id: _terrainSourceId,
          url: 'mapbox://mapbox.mapbox-terrain-dem-v1',
        ),
      );
    }
  }

  Future<void> _toggleHillshade() async {
    if (_hillshade) {
      setState(() => _hillshade = false);
      await widget.mapController.style.removeStyleLayer(_hillshadeLayerId);
    } else {
      setState(() => _hillshade = true);
      await _addTerrainSource();
      await widget.mapController.style.addLayer(
        HillshadeLayer(
          id: _hillshadeLayerId,
          sourceId: _terrainSourceId,
          hillshadeShadowColor: 0x404040,
          hillshadeHighlightColor: 0x404040,
        ),
      );
    }
  }

  Future<void> _toggle3D() async {
    if (_3D) {
      setState(() => _3D = false);
      await widget.mapController.style
          .setStyleTerrainProperty("exaggeration", "0");
      // while exaggeration is 0 this does not matter but it is needed so that setting it back to 60 works
      await widget.mapController.pitchBy(-_pitch, MapAnimationOptions());
    } else {
      setState(() => _3D = true);
      await _addTerrainSource();
      await widget.mapController.style
          .setStyleTerrainProperty("source", _terrainSourceId);
      await widget.mapController.style
          .setStyleTerrainProperty("exaggeration", _exaggeration);
      await widget.mapController.pitchBy(_pitch, MapAnimationOptions());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: Defaults.edgeInsets.normal,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => widget.mapController.style
                    .setStyleURI(MapboxStyles.OUTDOORS),
                style: style,
                child: const Icon(AppIcons.mountains),
              ),
              ElevatedButton(
                onPressed: () => widget.mapController.style
                    .setStyleURI(MapboxStyles.MAPBOX_STREETS),
                style: style,
                child: const Icon(AppIcons.car),
              ),
              ElevatedButton(
                onPressed: () => widget.mapController.style
                    .setStyleURI(MapboxStyles.SATELLITE),
                style: style,
                child: const Icon(AppIcons.satellite),
              ),
            ],
          ),
          Defaults.sizedBox.vertical.normal,
          ElevatedButton(
            onPressed: _toggleHillshade,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_hillshade ? AppIcons.close : AppIcons.add),
                Defaults.sizedBox.horizontal.normal,
                const Text("Hillshade"),
              ],
            ),
          ),
          Defaults.sizedBox.vertical.normal,
          ElevatedButton(
            onPressed: _toggle3D,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_3D ? AppIcons.close : AppIcons.add),
                Defaults.sizedBox.horizontal.normal,
                const Text("3D"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
