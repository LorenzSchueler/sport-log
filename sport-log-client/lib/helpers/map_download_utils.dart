import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:sport_log/helpers/lat_lng.dart';

class OfflineRegion {
  OfflineRegion(this.tileRegion, this.metadata);

  TileRegion tileRegion;
  Map<String, Object?> metadata;
}

class MapDownloadUtils extends ChangeNotifier {
  MapDownloadUtils({
    required this.onSuccess,
    required this.onError,
  });

  final Future<void> Function()? onSuccess;
  final Future<void> Function(String)? onError;

  static late final TileStore _tileStore;

  List<OfflineRegion> _regions = [];
  List<OfflineRegion> get regions => _regions;

  int get _nextId =>
      (_regions
              .map((region) => int.tryParse(region.tileRegion.id))
              .whereNotNull()
              .maxOrNull ??
          0) +
      1;

  double? _progress;
  double? get progress => _progress;
  bool _error = false;

  bool _disposed = false;

  static Future<void> globalInit() async {
    _tileStore = await TileStore.createDefault();
  }

  Future<void> init() => _updateRegions();

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _updateRegions() async {
    final regions = await _tileStore.allTileRegions();
    _regions = [
      for (final region in regions)
        OfflineRegion(region, await _tileStore.tileRegionMetadata(region.id)),
    ];
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> deleteRegion(TileRegion region) async {
    await _tileStore.removeRegion(region.id);
    await _updateRegions();
  }

  Future<void> downloadRegion(LatLngBounds bounds) async {
    final loadOptions = TileRegionLoadOptions(
      geometry: bounds.toPolygon().toJson(),
      descriptorsOptions: [
        TilesetDescriptorOptions(
          styleURI: MapboxStyles.OUTDOORS,
          minZoom: 6,
          maxZoom: 14, // 16 uses too many tiles
        ),
      ],
      acceptExpired: true,
      networkRestriction: NetworkRestriction.DISALLOW_EXPENSIVE,
      metadata: {
        "datetime": DateTime.now().toIso8601String(),
        "bounds": bounds.toList(), // .toPolygon().toJson() causes crash
      },
    );

    _progress = 0.0;
    notifyListeners();

    final TileRegion tileRegion;
    try {
      tileRegion = await _tileStore.loadTileRegion(
        _nextId.toString(),
        loadOptions,
        _onMapDownload,
      );
    } on PlatformException {
      _progress = null;
      notifyListeners();
      await onError?.call(
        "Maximum tile count exceeded. Delete other offline regions or choose a smaller region.",
      );
      return;
    }

    _progress = null;
    if (_error ||
        tileRegion.completedResourceCount < tileRegion.requiredResourceCount) {
      _error = false;
      notifyListeners();
      await onError?.call("Some tiles could not be downloaded.");
    } else {
      await _updateRegions();
      await onSuccess?.call();
    }
  }

  Future<void> _onMapDownload(TileRegionLoadProgress status) async {
    if (status.erroredResourceCount > 0) {
      _error = true;
    }
    _progress = status.completedResourceCount / status.requiredResourceCount;
    if (!_disposed) {
      notifyListeners();
    }
  }
}
