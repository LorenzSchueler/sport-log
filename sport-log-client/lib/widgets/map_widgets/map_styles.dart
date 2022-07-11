import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/widgets/app_icons.dart';

class MapStylesButton extends StatelessWidget {
  const MapStylesButton({
    required this.mapController,
    required this.onStyleChange,
    super.key,
  });

  final MapboxMapController mapController;
  final void Function(String) onStyleChange;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: null,
      child: const Icon(AppIcons.layers),
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        builder: (context) => MapStylesBottomSheet(
          mapController: mapController,
          onStyleChange: onStyleChange,
        ),
      ),
    );
  }
}

class MapStylesBottomSheet extends StatefulWidget {
  const MapStylesBottomSheet({
    required this.mapController,
    required this.onStyleChange,
    super.key,
  });

  final MapboxMapController mapController;
  final void Function(String style) onStyleChange;

  @override
  State<MapStylesBottomSheet> createState() => _MapStylesBottomSheetState();
}

class _MapStylesBottomSheetState extends State<MapStylesBottomSheet> {
  bool _hillshade = false;

  static const _hillshadeSourceId = "mapbox-terrain-dem-v1";
  static const _hillshadeLayerId = "custom-hillshade";

  final style = ButtonStyle(
    shape: MaterialStateProperty.all(const CircleBorder()),
    padding: MaterialStateProperty.all(const EdgeInsets.all(10)),
  );

  Future<void> _toggleHillshade() async {
    if (_hillshade) {
      setState(() => _hillshade = false);
      await widget.mapController.removeLayer(_hillshadeLayerId);
      await widget.mapController.removeSource(_hillshadeSourceId);
    } else {
      setState(() => _hillshade = true);
      await widget.mapController.addSource(
        _hillshadeSourceId,
        const RasterDemSourceProperties(
          url: 'mapbox://mapbox.mapbox-terrain-dem-v1',
        ),
      );
      await widget.mapController.addHillshadeLayer(
        _hillshadeSourceId,
        _hillshadeLayerId,
        HillshadeLayerProperties(
          hillshadeShadowColor:
              const Color.fromARGB(255, 60, 60, 60).toHexStringRGB(),
          hillshadeHighlightColor:
              const Color.fromARGB(255, 60, 60, 60).toHexStringRGB(),
        ),
      );
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
                onPressed: () => widget.onStyleChange(MapboxStyles.OUTDOORS),
                style: style,
                child: const Icon(AppIcons.mountains),
              ),
              ElevatedButton(
                onPressed: () =>
                    widget.onStyleChange(MapboxStyles.MAPBOX_STREETS),
                style: style,
                child: const Icon(AppIcons.car),
              ),
              ElevatedButton(
                onPressed: () => widget.onStyleChange(MapboxStyles.SATELLITE),
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
        ],
      ),
    );
  }
}
