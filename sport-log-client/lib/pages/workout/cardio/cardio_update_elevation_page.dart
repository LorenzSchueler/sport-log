import 'package:collection/collection.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/map_controller.dart';
import 'package:sport_log/helpers/page_return.dart';
import 'package:sport_log/models/cardio/cardio_session_description.dart';
import 'package:sport_log/models/cardio/position.dart';
import 'package:sport_log/pages/workout/charts/duration_chart.dart';
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
  bool _changed = false;

  static const _elevationColor = Color.fromARGB(255, 170, 130, 100);
  late final DurationChartLine _elevationLine = _getElevationLine();
  DurationChartLine _getElevationLine() =>
      DurationChartLine.fromValues<Position>(
        values: _cardioSessionDescription.cardioSession.track,
        getDuration: (position) => position.time,
        getGroupValue: (positions, _) =>
            positions.map((p) => p.elevation).average,
        lineColor: _elevationColor,
        absolute: false,
      );

  static const _updatedElevationColor = Colors.red;
  late DurationChartLine _updatedElevationLine = _getUpdatedElevationLine();
  DurationChartLine _getUpdatedElevationLine() =>
      DurationChartLine.fromValues<Position>(
        values: _cardioSessionDescription.cardioSession.track,
        getDuration: (position) => position.time,
        getGroupValue: (positions, _) =>
            positions.map((p) => p.elevation).average,
        lineColor: _updatedElevationColor,
        absolute: false,
      );

  Future<void> _updateElevation() async {
    final track = _cardioSessionDescription.cardioSession.track;
    if (track != null) {
      for (final (i, pos) in track.indexed) {
        final elevation =
            await _elevationMapController?.getElevation(pos.latLng);
        if (elevation != null) {
          pos.elevation = elevation;
        } else {
          if (mounted) {
            await showMessageDialog(
              context: context,
              title: "Failed To Fetch Elevation",
              text: "Internet connection or offline maps required.",
            );
          }
          return;
        }
        if (mounted) {
          setState(() => _progress = i / track.length);
        } else {
          return;
        }
      }
    }
    if (mounted) {
      setState(() {
        _cardioSessionDescription.cardioSession.setAscentDescent();
        _updatedElevationLine = _getUpdatedElevationLine();
        _progress = null;
        _changed = true;
      });
    }
  }

  void _return({required bool apply}) {
    if (apply) {
      Navigator.pop(
        context,
        // needed for cardio edit page
        ReturnObject.updated(_cardioSessionDescription),
      );
    } else {
      Navigator.pop(context);
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
              Expanded(
                child: DurationChart(
                  chartLines: [
                    _elevationLine,
                    if (_changed) _updatedElevationLine,
                  ],
                ),
              ),
              ElevationMap(
                onMapCreated: (x) => _elevationMapController = x,
              ),
              if (_progress != null) LinearProgressIndicator(value: _progress),
              Defaults.sizedBox.vertical.normal,
              _changed
                  ? Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            icon: const Icon(AppIcons.close),
                            label: const Text("Cancel"),
                            onPressed: () => _return(apply: false),
                            style: ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll(
                                Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ),
                        Defaults.sizedBox.horizontal.normal,
                        Expanded(
                          child: FilledButton.icon(
                            icon: const Icon(AppIcons.check),
                            label: const Text("Apply"),
                            onPressed: () => _return(apply: true),
                            style: ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll(
                                Theme.of(context).colorScheme.errorContainer,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(AppIcons.trendingUp),
                        label: const Text("Update Elevation"),
                        onPressed: _progress == null ? _updateElevation : null,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
