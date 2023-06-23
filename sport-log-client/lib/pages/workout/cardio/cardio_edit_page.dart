import 'package:flutter/material.dart' hide Route;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:sport_log/data_provider/data_providers/cardio_data_provider.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/map_controller.dart';
import 'package:sport_log/helpers/page_return.dart';
import 'package:sport_log/helpers/pointer.dart';
import 'package:sport_log/helpers/validation.dart';
import 'package:sport_log/models/cardio/cardio_session_description.dart';
import 'package:sport_log/routes.dart';
import 'package:sport_log/theme.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/dialogs/dialogs.dart';
import 'package:sport_log/widgets/input_fields/edit_tile.dart';
import 'package:sport_log/widgets/map_widgets/mapbox_map_wrapper.dart';
import 'package:sport_log/widgets/picker/datetime_picker.dart';
import 'package:sport_log/widgets/picker/picker.dart';
import 'package:sport_log/widgets/pop_scopes.dart';

class CardioEditPage extends StatefulWidget {
  const CardioEditPage({
    required this.cardioSessionDescription,
    required this.isNew,
    super.key,
  });

  final CardioSessionDescription cardioSessionDescription;
  final bool isNew;

  @override
  State<CardioEditPage> createState() => _CardioEditPageState();
}

class _CardioEditPageState extends State<CardioEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _dataProvider = CardioSessionDescriptionDataProvider();

  MapController? _mapController;

  final NullablePointer<PolylineAnnotation> _trackLine =
      NullablePointer.nullPointer();
  final NullablePointer<PolylineAnnotation> _routeLine =
      NullablePointer.nullPointer();

  late CardioSessionDescription _cardioSessionDescription =
      widget.cardioSessionDescription.clone();

  late final TextEditingController _distanceController = TextEditingController(
    text: _cardioSessionDescription.cardioSession.distance == null
        ? null
        : (_cardioSessionDescription.cardioSession.distance! / 1000).toString(),
  );
  late final TextEditingController _ascentController = TextEditingController(
    text: _cardioSessionDescription.cardioSession.ascent?.toString(),
  );
  late final TextEditingController _descentController = TextEditingController(
    text: _cardioSessionDescription.cardioSession.descent?.toString(),
  );
  late final TextEditingController _caloriesController = TextEditingController(
    text: _cardioSessionDescription.cardioSession.calories?.toString(),
  );
  late final TextEditingController _avgCadenceController =
      TextEditingController(
    text: _cardioSessionDescription.cardioSession.avgCadence?.toString(),
  );
  late final TextEditingController _avgHeartRateController =
      TextEditingController(
    text: _cardioSessionDescription.cardioSession.avgHeartRate?.toString(),
  );

  void _updateTextFields() {
    // only text fields which values are changed by cutting or updating elevation have to be updated
    _distanceController.text =
        _cardioSessionDescription.cardioSession.distance == null
            ? ""
            : (_cardioSessionDescription.cardioSession.distance! / 1000)
                .toString();
    _ascentController.text =
        _cardioSessionDescription.cardioSession.ascent?.toString() ?? "";
    _descentController.text =
        _cardioSessionDescription.cardioSession.descent?.toString() ?? "";
    _caloriesController.text =
        _cardioSessionDescription.cardioSession.calories?.toString() ?? "";
    _avgCadenceController.text =
        _cardioSessionDescription.cardioSession.avgCadence?.toString() ?? "";
    _avgHeartRateController.text =
        _cardioSessionDescription.cardioSession.avgHeartRate?.toString() ?? "";
  }

  Future<void> _saveCardioSession() async {
    final result = widget.isNew
        ? await _dataProvider.createSingle(_cardioSessionDescription)
        : await _dataProvider.updateSingle(_cardioSessionDescription);
    if (mounted) {
      if (result.isSuccess) {
        Navigator.pop(
          context,
          // needed for cardio details page
          ReturnObject.isNew(widget.isNew, _cardioSessionDescription),
        );
      } else {
        await showMessageDialog(
          context: context,
          text:
              "${widget.isNew ? 'Creating' : 'Updating'} Cardio Session failed:\n${result.failure}",
        );
      }
    }
  }

  Future<void> _deleteCardioSession() async {
    final delete = await showDeleteWarningDialog(context, "Cardio Session");
    if (!delete) {
      return;
    }
    if (!widget.isNew) {
      final result =
          await _dataProvider.deleteSingle(_cardioSessionDescription);
      if (mounted) {
        if (result.isSuccess) {
          Navigator.pop(
            context,
            // needed for cardio details page
            ReturnObject.deleted(_cardioSessionDescription),
          );
        } else {
          await showMessageDialog(
            context: context,
            text: "Deleting Cardio Session failed:\n${result.failure}",
          );
        }
      }
    } else if (mounted) {
      Navigator.pop(
        context,
        // needed for cardio details page
        ReturnObject.deleted(_cardioSessionDescription),
      );
    }
  }

  Future<void> _showUpdateElevationPage() async {
    if (_cardioSessionDescription.cardioSession.track != null &&
        _cardioSessionDescription.cardioSession.track!.isNotEmpty) {
      final returnObj = await Navigator.pushNamed(
        context,
        Routes.cardioUpdateElevation,
        arguments: _cardioSessionDescription,
      );
      if (returnObj is ReturnObject<CardioSessionDescription> && mounted) {
        if (returnObj.action == ReturnAction.updated) {
          setState(() {
            _cardioSessionDescription = returnObj.payload;
          });
          _updateTextFields();
        }
      }
    }
  }

  Future<void> _showCutPage() async {
    if (_cardioSessionDescription.cardioSession.time != null) {
      final returnObj = await Navigator.pushNamed(
        context,
        Routes.cardioCut,
        arguments: _cardioSessionDescription,
      );
      if (returnObj is ReturnObject<CardioSessionDescription> && mounted) {
        if (returnObj.action == ReturnAction.updated) {
          setState(() {
            _cardioSessionDescription = returnObj.payload;
          });
          _updateTextFields();
          await _setBoundsAndLines();
        }
      }
    }
  }

  Future<void> _onMapCreated(MapController mapController) async {
    _mapController = mapController;
    await _setBoundsAndLines();
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

  @override
  Widget build(BuildContext context) {
    return DiscardWarningOnPop(
      child: Scaffold(
        appBar: AppBar(
          title: Text("${widget.isNew ? 'Create' : 'Edit'} Cardio Session"),
          actions: [
            if (_cardioSessionDescription.cardioSession.track != null)
              IconButton(
                onPressed: _showUpdateElevationPage,
                icon: const Icon(AppIcons.trendingUp),
              ),
            if (_cardioSessionDescription.cardioSession.time != null)
              IconButton(
                onPressed: _showCutPage,
                icon: const Icon(AppIcons.cut),
              ),
            IconButton(
              onPressed: _deleteCardioSession,
              icon: const Icon(AppIcons.delete),
            ),
            IconButton(
              onPressed: _formKey.currentContext != null &&
                      _formKey.currentState!.validate() &&
                      _cardioSessionDescription.isValidBeforeSanitation()
                  ? _saveCardioSession
                  : null,
              icon: const Icon(AppIcons.save),
            )
          ],
        ),
        body: Column(
          children: [
            if (_cardioSessionDescription.cardioSession.track != null)
              SizedBox(
                height: 250,
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
            Form(
              key: _formKey,
              child: Expanded(
                child: ListView(
                  padding: Defaults.edgeInsets.normal,
                  children: [
                    EditTile(
                      leading: AppIcons.exercise,
                      caption: "Movement",
                      child: Text(_cardioSessionDescription.movement.name),
                      onTap: () async {
                        final movement = await showMovementPicker(
                          selectedMovement: _cardioSessionDescription.movement,
                          cardioOnly: true,
                          context: context,
                        );
                        if (mounted && movement != null) {
                          setState(() {
                            _cardioSessionDescription.cardioSession.movementId =
                                movement.id;
                            _cardioSessionDescription.movement = movement;
                          });
                        }
                      },
                    ),
                    EditTile(
                      leading: AppIcons.sports,
                      caption: "Cardio Type",
                      child: Text(
                        _cardioSessionDescription.cardioSession.cardioType.name,
                      ),
                      onTap: () async {
                        final cardioType = await showCardioTypePicker(
                          selectedCardioType: _cardioSessionDescription
                              .cardioSession.cardioType,
                          context: context,
                        );
                        if (mounted && cardioType != null) {
                          setState(() {
                            _cardioSessionDescription.cardioSession.cardioType =
                                cardioType;
                          });
                        }
                      },
                    ),
                    EditTile(
                      leading: AppIcons.calendar,
                      caption: "Start Time",
                      child: Text(
                        _cardioSessionDescription.cardioSession.datetime
                            .toHumanDateTime(),
                      ),
                      onTap: () async {
                        final datetime = await showDateTimePicker(
                          context: context,
                          initial:
                              _cardioSessionDescription.cardioSession.datetime,
                        );
                        if (mounted && datetime != null) {
                          setState(() {
                            _cardioSessionDescription.cardioSession.datetime =
                                datetime;
                          });
                        }
                      },
                    ),
                    EditTile(
                      leading: AppIcons.route,
                      caption: "Route",
                      child: Text(_cardioSessionDescription.route?.name ?? ""),
                      onTap: () async {
                        final route = await showRoutePicker(
                          selectedRoute: _cardioSessionDescription.route,
                          context: context,
                        );
                        if (mounted && route != null) {
                          setState(() {
                            _cardioSessionDescription.cardioSession.routeId =
                                route.id;
                            _cardioSessionDescription.route = route;
                          });
                        }
                      },
                    ),
                    TextFormField(
                      controller: _distanceController,
                      keyboardType: TextInputType.number,
                      validator: (distance) =>
                          distance == null || distance.isEmpty
                              ? null
                              : Validator.validateDoubleGtZero(distance),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      onChanged: (distance) => setState(() {
                        if (distance.isEmpty) {
                          _cardioSessionDescription.cardioSession.distance =
                              null;
                        } else if (Validator.validateDoubleGtZero(
                              distance,
                            ) ==
                            null) {
                          _cardioSessionDescription.cardioSession.distance =
                              (double.parse(distance) * 1000).round();
                        }
                      }),
                      decoration:
                          Theme.of(context).textFormFieldDecoration.copyWith(
                                icon: const Icon(AppIcons.ruler),
                                labelText: "Distance (km)",
                              ),
                    ),
                    TextFormField(
                      controller: _ascentController,
                      keyboardType: TextInputType.number,
                      validator: (ascent) => ascent == null || ascent.isEmpty
                          ? null
                          : Validator.validateIntGeZero(ascent),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      onChanged: (ascent) => setState(() {
                        if (ascent.isEmpty) {
                          _cardioSessionDescription.cardioSession.distance =
                              null;
                        } else if (Validator.validateIntGeZero(ascent) ==
                            null) {
                          _cardioSessionDescription.cardioSession.ascent =
                              int.parse(ascent);
                        }
                      }),
                      decoration:
                          Theme.of(context).textFormFieldDecoration.copyWith(
                                icon: const Icon(AppIcons.trendingUp),
                                labelText: "Ascent (m)",
                              ),
                    ),
                    TextFormField(
                      controller: _descentController,
                      keyboardType: TextInputType.number,
                      validator: (descent) => descent == null || descent.isEmpty
                          ? null
                          : Validator.validateIntGeZero(descent),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      onChanged: (descent) => setState(() {
                        if (descent.isEmpty) {
                          _cardioSessionDescription.cardioSession.distance =
                              null;
                        } else if (Validator.validateIntGeZero(descent) ==
                            null) {
                          _cardioSessionDescription.cardioSession.descent =
                              int.parse(descent);
                        }
                      }),
                      decoration:
                          Theme.of(context).textFormFieldDecoration.copyWith(
                                icon: const Icon(AppIcons.trendingDown),
                                labelText: "Descent (m)",
                              ),
                    ),
                    EditTile.optionalActionChip(
                      leading: AppIcons.timeInterval,
                      caption: "Time",
                      showActionChip:
                          _cardioSessionDescription.cardioSession.time == null,
                      onActionChipTap: () => setState(() {
                        _cardioSessionDescription.cardioSession.time =
                            const Duration(minutes: 1);
                      }),
                      builder: () => Text(
                        _cardioSessionDescription.cardioSession.time!.formatHms,
                      ),
                      onTap: () async {
                        final duration = await showScrollableDurationPicker(
                          context: context,
                          initialDuration:
                              _cardioSessionDescription.cardioSession.time,
                        );
                        if (mounted && duration != null) {
                          setState(
                            () => _cardioSessionDescription.cardioSession.time =
                                duration,
                          );
                        }
                      },
                      onCancel: () => setState(() {
                        _cardioSessionDescription.cardioSession.time = null;
                      }),
                    ),
                    TextFormField(
                      controller: _caloriesController,
                      keyboardType: TextInputType.number,
                      validator: (calories) =>
                          calories == null || calories.isEmpty
                              ? null
                              : Validator.validateIntGtZero(calories),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      onChanged: (calories) => setState(() {
                        if (calories.isEmpty) {
                          _cardioSessionDescription.cardioSession.distance =
                              null;
                        } else if (Validator.validateIntGtZero(
                              calories,
                            ) ==
                            null) {
                          _cardioSessionDescription.cardioSession.calories =
                              int.parse(calories);
                        }
                      }),
                      decoration:
                          Theme.of(context).textFormFieldDecoration.copyWith(
                                icon: const Icon(AppIcons.food),
                                labelText: "Calories",
                              ),
                    ),
                    TextFormField(
                      controller: _avgCadenceController,
                      keyboardType: TextInputType.number,
                      validator: (avgCadence) =>
                          avgCadence == null || avgCadence.isEmpty
                              ? null
                              : Validator.validateIntGtZero(avgCadence),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      onChanged: (avgCadence) => setState(() {
                        if (avgCadence.isEmpty) {
                          _cardioSessionDescription.cardioSession.distance =
                              null;
                        } else if (Validator.validateIntGtZero(
                              avgCadence,
                            ) ==
                            null) {
                          _cardioSessionDescription.cardioSession.avgCadence =
                              int.parse(avgCadence);
                        }
                      }),
                      decoration:
                          Theme.of(context).textFormFieldDecoration.copyWith(
                                icon: const Icon(AppIcons.gauge),
                                labelText: "Cadence",
                              ),
                    ),
                    TextFormField(
                      controller: _avgHeartRateController,
                      keyboardType: TextInputType.number,
                      validator: (avgHeartRate) =>
                          avgHeartRate == null || avgHeartRate.isEmpty
                              ? null
                              : Validator.validateIntGtZero(avgHeartRate),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      onChanged: (avgHeartRate) => setState(() {
                        if (avgHeartRate.isEmpty) {
                          _cardioSessionDescription.cardioSession.distance =
                              null;
                        } else if (Validator.validateIntGtZero(
                              avgHeartRate,
                            ) ==
                            null) {
                          _cardioSessionDescription.cardioSession.avgHeartRate =
                              int.parse(avgHeartRate);
                        }
                      }),
                      decoration:
                          Theme.of(context).textFormFieldDecoration.copyWith(
                                icon: const Icon(AppIcons.heartbeat),
                                labelText: "Heart Rate",
                              ),
                    ),
                    TextFormField(
                      onChanged: (comments) => setState(() {
                        _cardioSessionDescription.cardioSession.comments =
                            comments;
                      }),
                      initialValue:
                          _cardioSessionDescription.cardioSession.comments,
                      decoration:
                          Theme.of(context).textFormFieldDecoration.copyWith(
                                icon: const Icon(AppIcons.comment),
                                labelText: "Comments",
                              ),
                      keyboardType: TextInputType.multiline,
                      minLines: 1,
                      maxLines: 5,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
