import 'package:flutter/foundation.dart';

class MapDownloadUtils extends ChangeNotifier {
  factory MapDownloadUtils({
    required Future<void> Function()? onSuccess,
    required Future<void> Function()? onError,
  }) {
    return MapDownloadUtils._(onSuccess: onSuccess, onError: onError)
      .._updateRegions();
  }

  MapDownloadUtils._({
    required this.onSuccess,
    required this.onError,
  });

  final Future<void> Function()? onSuccess;
  final Future<void> Function()? onError;

  //List<OfflineRegion> _regions = [];
  //List<OfflineRegion> get regions => _regions;

  double? _progress;
  double? get progress => _progress;

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _updateRegions() async {
    //_regions = await getListOfRegions(accessToken: Config.instance.accessToken);
    if (!_disposed) {
      notifyListeners();
    }
  }

  //Future<void> deleteRegion(OfflineRegion region) async {
  //await deleteOfflineRegion(region.id);
  //await _updateRegions();
  //}

  //Future<void> _onMapDownload(DownloadRegionStatus status) async {
  //if (!_disposed) {
  //if (status.runtimeType.isOk) {
  //_progress = null;
  //await _updateRegions();
  //notifyListeners();
  //await onSuccess?.call();
  //} else if (status.runtimeType == InProgress) {
  //_progress = (status as InProgress).progress / 100;
  //notifyListeners();
  //} else if (status.runtimeType == Error) {
  //_progress = null;
  //notifyListeners();
  //await onError?.call();
  //}
  //}
  //}

  //Future<OfflineRegion> downloadRegion(LatLngBounds bounds) {
  //return downloadOfflineRegion(
  //OfflineRegionDefinition(
  //bounds: bounds,
  //minZoom: 0,
  //maxZoom: 16,
  //mapStyleUrl: MapboxStyles.OUTDOORS,
  //),
  //onEvent: _onMapDownload,
  //accessToken: Config.instance.accessToken,
  //metadata: <String, dynamic>{"datetime": DateTime.now().toIso8601String()},
  //);
  //}
}
