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

  final List<NullablePointer<PolylineAnnotation>> _trackLines = [
    NullablePointer.nullPointer(),
    NullablePointer.nullPointer(),
    NullablePointer.nullPointer(),
  ];
  final NullablePointer<PolylineAnnotation> _routeLine =
      NullablePointer.nullPointer();
  final NullablePointer<CircleAnnotation> _cutStartMarker =
      NullablePointer.nullPointer();
  final NullablePointer<CircleAnnotation> _cutEndMarker =
      NullablePointer.nullPointer();

  Future<void> _onMapCreated(MapController mapController) async {
    _mapController = mapController;
    await _setBoundsAndRoute();
    await _updateCutMarkerAndTrack();
  }

  Future<void> _setBoundsAndRoute() async {
    await _mapController?.setBoundsFromTracks(
      _cardioSessionDescription.cardioSession.track,
      _cardioSessionDescription.route?.track,
      padded: true,
    );
    await _mapController?.updateRouteLine(
      _routeLine,
      _cardioSessionDescription.route?.track,
    );
  }

  Future<void> _updateCutMarkerAndTrack() async {
    final startLtEnd = _cutStartDuration < _cutEndDuration;
    final time1 = startLtEnd ? _cutStartDuration : _cutEndDuration;
    final time2 = startLtEnd ? _cutEndDuration : _cutStartDuration;

    final track = _cardioSessionDescription.cardioSession.track;
    final latLngs1 = track?.where((pos) => pos.time <= time1);
    final latLngs2 =
        track?.where((pos) => pos.time >= time1 && pos.time <= time2);
    final latLngs3 = track?.where((pos) => pos.time >= time2);
    const cutLineOpacity = 0.4;
    await _mapController?.updateTrackLine(
      _trackLines[0],
      latLngs1,
      lineOpacity: startLtEnd ? cutLineOpacity : null,
    );
    await _mapController?.updateTrackLine(
      _trackLines[1],
      latLngs2,
      lineOpacity: startLtEnd ? null : cutLineOpacity,
    );
    await _mapController?.updateTrackLine(
      _trackLines[2],
      latLngs3,
      lineOpacity: startLtEnd ? cutLineOpacity : null,
    );

    final startLatLng =
        track?.firstWhereOrNull((pos) => pos.time >= _cutStartDuration)?.latLng;
    final endLatLng = track?.reversed
        .firstWhereOrNull((pos) => pos.time <= _cutEndDuration)
        ?.latLng;
    await _mapController?.updateTrackMarker(_cutStartMarker, startLatLng);
    await _mapController?.updateTrackMarker(_cutEndMarker, endLatLng);
  }

  Future<void> _cutCardioSession() async {
    final approved = await showApproveDialog(
      context: context,
      title: "Cut Cardio Session",
      text:
          "This can not be reversed. All cut out data will be permanently lost.",
    );
    if (approved) {
      final cutSession = _cardioSessionDescription.cardioSession
          .cut(_cutStartDuration, _cutEndDuration);
      if (cutSession == null) {
        return;
      }
      _cardioSessionDescription.cardioSession = cutSession;
      if (mounted) {
        Navigator.pop(
          context,
          // needed for cardio edit page
          ReturnObject.updated(_cardioSessionDescription),
        );
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
                  showAddLocationButton: false,
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
                          if (context.mounted && duration != null) {
                            setState(() => _cutStartDuration = duration);
                            await _updateCutMarkerAndTrack();
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
                          if (context.mounted && duration != null) {
                            setState(() => _cutEndDuration = duration);
                            await _updateCutMarkerAndTrack();
                          }
                        },
                        child: Text(_cutEndDuration.formatHms),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(AppIcons.close),
                          label: const Text("Cancel"),
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                      Defaults.sizedBox.horizontal.normal,
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(AppIcons.cut),
                          label: const Text("Cut"),
                          onPressed: _cutCardioSession,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.errorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
