import 'package:flutter/material.dart' hide Route;
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/map_controller.dart';
import 'package:sport_log/helpers/page_return.dart';
import 'package:sport_log/models/cardio/cardio_session_description.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/dialogs.dart';
import 'package:sport_log/widgets/map_widgets/static_mapbox_map.dart';
import 'package:sport_log/widgets/pop_scopes.dart';

class CardioUpdateElevationPage extends StatefulWidget {
  const CardioUpdateElevationPage({
    required this.cardioSessionDescription,
    super.key,
  });

  final CardioSessionDescription cardioSessionDescription;

  @override
  State<CardioUpdateElevationPage> createState() =>
      _CardioUpdateElevationPageState();
}

class _CardioUpdateElevationPageState extends State<CardioUpdateElevationPage> {
  _CardioUpdateElevationPageState();

  late final CardioSessionDescription _cardioSessionDescription =
      widget.cardioSessionDescription.clone();

  ElevationMapController? _elevationMapController;
  double? _progress;

  Future<void> _updateElevation() async {
    final approved = await showApproveDialog(
      context: context,
      title: "Update Elevation",
      text:
          "The old elevation data will be permanently lost. The new elevations is taken from the map. This requires internet or offline maps.",
    );
    if (!approved) {
      return;
    }
    final track = _cardioSessionDescription.cardioSession.track;
    if (track != null) {
      for (var i = 0; i < track.length; i++) {
        final pos = track[i];
        final elevation =
            await _elevationMapController?.getElevation(pos.latLng);
        if (elevation != null) {
          pos.elevation = elevation;
        } else {
          if (mounted) {
            await showMessageDialog(
              context: context,
              text: "Failed to fetch elevation data.",
            );
          }
          return;
        }
        setState(() {
          _progress = i / track.length;
        });
      }
    }
    setState(() {
      _cardioSessionDescription.cardioSession.setAscentDescent();
    });
    if (mounted) {
      Navigator.pop(
        context,
        // needed for cardio edit page
        ReturnObject.updated(_cardioSessionDescription),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DiscardWarningOnPop(
      child: Scaffold(
        appBar: AppBar(title: const Text("Update Elevation")),
        body: Padding(
          padding: Defaults.edgeInsets.normal,
          child: Column(
            children: [
              ElevationMap(
                onMapCreated: (x) => _elevationMapController = x,
              ),
              if (_progress != null) LinearProgressIndicator(value: _progress),
              Defaults.sizedBox.vertical.normal,
              ElevatedButton(
                onPressed: _progress == null ? _updateElevation : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(AppIcons.trendingUp),
                    Defaults.sizedBox.horizontal.normal,
                    const Text("Update Elevation"),
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
        ),
      ),
    );
  }
}
