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

  static const _hillshadeSourceId = "mapbox-terrain-dem-v1";
  static const _hillshadeLayerId = "custom-hillshade";

  final style = ButtonStyle(
    shape: MaterialStateProperty.all(const CircleBorder()),
    padding: MaterialStateProperty.all(const EdgeInsets.all(10)),
  );

  Future<void> _toggleHillshade() async {
    if (_hillshade) {
      setState(() => _hillshade = false);
      await widget.mapController.style.removeStyleLayer(_hillshadeLayerId);
    } else {
      setState(() => _hillshade = true);
      if (!await widget.mapController.style
          .styleSourceExists(_hillshadeSourceId)) {
        await widget.mapController.style.addSource(
          RasterDemSource(
            id: _hillshadeSourceId,
            url: 'mapbox://mapbox.mapbox-terrain-dem-v1',
          ),
        );
      }
      await widget.mapController.style.addLayer(
        HillshadeLayer(
          id: _hillshadeLayerId,
          sourceId: _hillshadeSourceId,
          hillshadeShadowColor: 0x404040,
          hillshadeHighlightColor: 0x404040,
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
        ],
      ),
    );
  }
}
