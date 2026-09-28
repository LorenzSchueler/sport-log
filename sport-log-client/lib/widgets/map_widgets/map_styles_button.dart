import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:material_ui/material_ui.dart' hide Visibility;
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/map_controller.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:synchronized/synchronized.dart';

enum MapStyle {
  // based on mapbox OUTDOORS
  // natural features - natural point label - text field formula
  //     coalesce(name_en, name) & "\n" & elevation_m
  outdoor(outdoorConst),
  street(MapboxStyles.STANDARD),
  // based on mapbox SATELLITE_STREETS
  // -> eject style components street and walking to be able to edit zoom extend
  // for all
  //     select data - zoom extend
  //         z12-z22 # there seems to be no data for < z12
  // road network - surface: road-street
  //     opacity: 0.8
  // road network - surface: road-minor
  //     color: hsl(35, 80%, 48%)
  //     opacity: 1
  //     width: 2
  //     dash-array: 5, 2
  // road network - surface: road-minor-case
  //     color: hsl(35, 80%, 0%)
  // walking, cycling, etc - surface - road-path
  // walking, cycling, etc - barriers-bridges - bridge-path
  // walking, cycling, etc - tunnels - tunnel-path
  //     color: hsl(35, 80%, 48%)
  //     opacity: 1
  //     width: 2
  //     dash-array: 2, 1
  // natural features - natural point label - text field formula
  //     coalesce(name_en, name) & "\n" & elevation_m
  // add layer terrain-v2 - contour
  //     color: white
  //     opacity: style with data conditions
  //         index is 5, 10: 0.2
  //         fallback: 0.1
  satelliteStreetsWithPaths("mapbox://styles/hi-ker/cm6dk2zkg004x01sg2hm36puk");

  const MapStyle(this.url);
  // This is needed when a const value is required because MapStyle.outdoor.url is not const.
  static const outdoorConst =
      "mapbox://styles/hi-ker/cm4pewm54007e01sacaks9r4z";
  final String url;
}

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

  Future<bool> isEnabled(MapController mapController);
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
      mapController.disableLayer(_hillshadeLayerId);

  @override
  Future<bool> isEnabled(MapController mapController) =>
      mapController.layerEnabled(_hillshadeLayerId);
}

class _SlopeOption extends _MapOption {
  const _SlopeOption();

  static const _slopeSourceId = "slope-source";
  static const _slopeSourceUrl = 'mapbox://hi-ker.central-alps-slope';
  static const _slopeLayerId = "slope-layer";

  @override
  Future<void> enable(MapController mapController) => mapController.enableLayer(
    _slopeSourceId,
    _slopeSourceUrl,
    _slopeLayerId,
    opacity: 0.4,
    minZoom: 10,
  );

  @override
  Future<void> disable(MapController mapController) =>
      mapController.disableLayer(_slopeLayerId);

  @override
  Future<bool> isEnabled(MapController mapController) =>
      mapController.layerEnabled(_slopeLayerId);
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

  @override
  Future<bool> isEnabled(MapController mapController) =>
      mapController.terrainEnabled();
}

class _MapStylesBottomSheetState extends State<MapStylesBottomSheet> {
  final _lock = Lock();
  bool _loaded = false;
  Set<_MapOption> _options = {};
  MapStyle _style = MapStyle.outdoor;

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
    final hasHillshade = await _HillshadeOption().isEnabled(
      widget.mapController,
    );
    final hasSlope = await _SlopeOption().isEnabled(widget.mapController);
    final hasTerrain = await _TerrainOption().isEnabled(widget.mapController);
    if (style == null) {
      return;
    }
    if (mounted) {
      setState(() {
        _style = MapStyle.values.firstWhere((s) => s.url == style);
        _options = {
          if (hasHillshade) const _HillshadeOption(),
          if (hasSlope) const _SlopeOption(),
          if (hasTerrain) const _TerrainOption(),
        };
        _loaded = true;
      });
    }
  }

  Future<void> _setStyle(Set<MapStyle> style) async {
    setState(() {
      _style = style.first;
      _options = {};
    });
    await _lock.synchronized(() async {
      await _applyOptions({});
      await widget.mapController.setStyle(style.first.url);
    });
  }

  Future<void> _setOptions(Set<_MapOption> options) async {
    setState(() => _options = options);
    await _lock.synchronized(() => _applyOptions(options));
  }

  /// Applies [options] based on the state of the map, since other changes
  /// may have been requested while the buttons showed an older state.
  Future<void> _applyOptions(Set<_MapOption> options) async {
    for (final option in const [
      _HillshadeOption(),
      _SlopeOption(),
      _TerrainOption(),
    ]) {
      final enabled = await option.isEnabled(widget.mapController);
      if (enabled && !options.contains(option)) {
        await option.disable(widget.mapController);
      } else if (!enabled && options.contains(option)) {
        await option.enable(widget.mapController);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: Defaults.edgeInsets.normal,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Map Type", style: Theme.of(context).textTheme.labelLarge),
          Defaults.sizedBox.vertical.small,
          SegmentedButton(
            segments: const [
              ButtonSegment(
                value: MapStyle.outdoor,
                icon: Icon(AppIcons.mountains),
                label: Text("Outdoor"),
              ),
              ButtonSegment(
                value: MapStyle.street,
                icon: Icon(AppIcons.car),
                label: Text("Street"),
              ),
              ButtonSegment(
                value: MapStyle.satelliteStreetsWithPaths,
                icon: Icon(AppIcons.satellite),
                label: Text("Satellite"),
              ),
            ],
            selected: {_style},
            onSelectionChanged: _loaded ? _setStyle : null,
            showSelectedIcon: false,
          ),
          Defaults.sizedBox.vertical.small,
          const Divider(),
          Text("Map Options", style: Theme.of(context).textTheme.labelLarge),
          Defaults.sizedBox.vertical.small,
          SegmentedButton(
            segments: const [
              ButtonSegment(
                value: _HillshadeOption(),
                icon: Icon(AppIcons.invertColors),
                label: Text("Hillshade"),
              ),
              ButtonSegment(
                value: _SlopeOption(),
                icon: Icon(AppIcons.colorLens),
                label: Text("Slope"),
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
            onSelectionChanged: _loaded ? _setOptions : null,
            showSelectedIcon: false,
          ),
        ],
      ),
    );
  }
}
