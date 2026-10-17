import 'package:material_ui/material_ui.dart';
import 'package:sport_log/helpers/map_controller.dart';
import 'package:sport_log/widgets/app_icons.dart';

enum ZoomDirection {
  zoomIn,
  zoomOut;

  bool get isZoomIn => this == ZoomDirection.zoomIn;
}

class ZoomMapButton extends StatelessWidget {
  const ZoomMapButton({
    required this.mapController,
    required this.zoomDirection,
    super.key,
  });

  final MapController mapController;
  final ZoomDirection zoomDirection;

  Future<void> _zoomMap() async {
    final zoom = await mapController.zoom;
    if (zoom != null) {
      await mapController.animateZoom(
        zoomDirection.isZoomIn ? zoom + 0.5 : zoom - 0.5,
      );
    }
  }

  Future<void> _zoomMapToMinPathZoom() async {
    const minPathZoom = 13.0;
    final zoom = await mapController.zoom;
    if (zoom != null &&
        (zoomDirection.isZoomIn ? zoom < minPathZoom : zoom > minPathZoom)) {
      await mapController.animateZoom(minPathZoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: _zoomMapToMinPathZoom,
      child: FloatingActionButton.small(
        heroTag: null,
        onPressed: _zoomMap,
        child: Icon(zoomDirection.isZoomIn ? AppIcons.add : AppIcons.remove),
      ),
    );
  }
}
