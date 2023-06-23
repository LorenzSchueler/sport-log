import 'package:collection/collection.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/map_controller.dart';
import 'package:sport_log/helpers/page_return.dart';
import 'package:sport_log/helpers/pointer.dart';
import 'package:sport_log/models/cardio/cardio_session_description.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/dialogs.dart';
import 'package:sport_log/widgets/input_fields/edit_tile.dart';
import 'package:sport_log/widgets/map_widgets/mapbox_map_wrapper.dart';
import 'package:sport_log/widgets/picker/datetime_picker.dart';
import 'package:sport_log/widgets/pop_scopes.dart';

class CardioCutPage extends StatefulWidget {
  const CardioCutPage({
    required this.cardioSessionDescription,
    super.key,
  });

  final CardioSessionDescription cardioSessionDescription;

  @override
  State<CardioCutPage> createState() => _CardioCutPageState();
}

class _CardioCutPageState extends State<CardioCutPage> {
  late final CardioSessionDescription _cardioSessionDescription =
      widget.cardioSessionDescription.clone();

  Duration _cutStartDuration = Duration.zero;
  late Duration _cutEndDuration = _cardioSessionDescription.cardioSession.time!;

  MapController? _mapController;

  final NullablePointer<PolylineAnnotation> _trackLine =
      NullablePointer.nullPointer();
  final NullablePointer<PolylineAnnotation> _routeLine =
      NullablePointer.nullPointer();
  final NullablePointer<CircleAnnotation> _cutStartMarker =
      NullablePointer.nullPointer();
  final NullablePointer<CircleAnnotation> _cutEndMarker =
      NullablePointer.nullPointer();

  Future<void> _onMapCreated(MapController mapController) async {
    _mapController = mapController;
    await _setBoundsAndLines();
    await _updateCutLocationMarker();
  }

  Future<void> _setBoundsAndLines() async {
    await _mapController?.setBoundsFromTracks(
      _cardioSessionDescription.cardioSession.track,
      _cardioSessionDescription.route?.track,
      padded: true,
    );
    await _mapController?.updateTrackLine(
      _trackLine,
      _cardioSessionDescription.cardioSession.track,
    );
    await _mapController?.updateRouteLine(
      _routeLine,
      _cardioSessionDescription.route?.track,
    );
  }

  Future<void> _updateCutLocationMarker() async {
    final startLatLng = _cardioSessionDescription.cardioSession.track
        ?.firstWhereOrNull((pos) => pos.time >= _cutStartDuration)
        ?.latLng;
    final endLatLng = _cardioSessionDescription.cardioSession.track?.reversed
        .firstWhereOrNull((pos) => pos.time <= _cutEndDuration)
        ?.latLng;
    await _mapController?.updateTrackMarker(_cutStartMarker, startLatLng);
    await _mapController?.updateTrackMarker(_cutEndMarker, endLatLng);
  }

  Future<void> _cutCardioSession() async {
    if (_cutStartDuration < _cutEndDuration) {
      final approved = await showApproveDialog(
        context: context,
        title: "Cut Cardio Session",
        text:
            "This can not be reversed. All cut out data will be permanently lost.",
      );
      if (approved) {
        _cardioSessionDescription.cardioSession
            .cut(_cutStartDuration, _cutEndDuration);
        if (mounted) {
          Navigator.pop(
            context,
            // needed for cardio edit page
            ReturnObject.updated(_cardioSessionDescription),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DiscardWarningOnPop(
      child: Scaffold(
        appBar: AppBar(title: const Text("Cut Cardio Session")),
        body: Column(
          children: [
            if (_cardioSessionDescription.cardioSession.track != null)
              Expanded(
                child: MapboxMapWrapper(
                  showFullscreenButton: false,
                  showMapStylesButton: true,
                  showSelectRouteButton: false,
                  showSetNorthButton: true,
                  showCurrentLocationButton: false,
                  showCenterLocationButton: false,
                  onMapCreated: _onMapCreated,
                ),
              ),
            Padding(
              padding: Defaults.edgeInsets.normal,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      EditTile(
                        leading: null,
                        caption: "Start",
                        shrinkWidth: true,
                        onTap: () async {
                          final duration = await showScrollableDurationPicker(
                            context: context,
                            initialDuration: _cutStartDuration,
                          );
                          if (mounted && duration != null) {
                            if (duration > _cutEndDuration) {
                              await showMessageDialog(
                                context: context,
                                text: "Start time can not be after End time.",
                              );
                            } else {
                              setState(() => _cutStartDuration = duration);
                              await _updateCutLocationMarker();
                            }
                          }
                        },
                        child: Text(_cutStartDuration.formatHms),
                      ),
                      EditTile(
                        leading: null,
                        caption: "End",
                        shrinkWidth: true,
                        onTap: () async {
                          final duration = await showScrollableDurationPicker(
                            context: context,
                            initialDuration: _cutEndDuration,
                          );
                          if (mounted && duration != null) {
                            if (duration < _cutStartDuration) {
                              await showMessageDialog(
                                context: context,
                                text: "End time can not be before Start time.",
                              );
                            } else {
                              setState(() => _cutEndDuration = duration);
                              await _updateCutLocationMarker();
                            }
                          }
                        },
                        child: Text(_cutEndDuration.formatHms),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: _cutCardioSession,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(AppIcons.cut),
                        Defaults.sizedBox.horizontal.normal,
                        const Text("Cut"),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(AppIcons.close),
                        Defaults.sizedBox.horizontal.normal,
                        const Text("Cancel"),
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
