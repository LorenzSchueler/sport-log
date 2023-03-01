import 'package:flutter/material.dart' hide Route;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:sport_log/data_provider/data_providers/all.dart';
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
import 'package:sport_log/widgets/dialogs/message_dialog.dart';
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

  Future<void> _saveCardioSession() async {
    final result = widget.isNew
        ? await _dataProvider.createSingle(_cardioSessionDescription)
        : await _dataProvider.updateSingle(_cardioSessionDescription);
    if (mounted) {
      if (result.isSuccess) {
        Navigator.pop(
          context,
          ReturnObject(
            action: widget.isNew ? ReturnAction.created : ReturnAction.updated,
            payload: _cardioSessionDescription,
          ), // needed for cardio details page
        );
      } else {
        await showMessageDialog(
          context: context,
          text: 'Creating Cardio Session failed:\n${result.failure}',
        );
      }
    }
  }

  Future<void> _deleteCardioSession() async {
    if (!widget.isNew) {
      await _dataProvider.deleteSingle(_cardioSessionDescription);
    }
    if (mounted) {
      Navigator.pop(
        context,
        ReturnObject(
          action: ReturnAction.deleted,
          payload: _cardioSessionDescription,
        ), // needed for cardio details page
      );
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
        setState(() {
          _cardioSessionDescription = returnObj.payload;
        });
        await _setBoundsAndLines();
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
          title: Text(
            widget.isNew ? "Create Cardio Session" : "Edit Cardio Session",
          ),
          actions: [
            IconButton(
              onPressed: _deleteCardioSession,
              icon: const Icon(AppIcons.delete),
            ),
            if (_cardioSessionDescription.cardioSession.time != null)
              IconButton(
                onPressed: _showCutPage,
                icon: const Icon(AppIcons.cut),
              ),
            IconButton(
              onPressed: _formKey.currentContext != null &&
                      _formKey.currentState!.validate() &&
                      _cardioSessionDescription.isValid()
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
                  showScale: true,
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
                      child: Text(
                        _cardioSessionDescription.movement.name,
                      ),
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
                      child: Text(
                        _cardioSessionDescription.route?.name ?? "",
                      ),
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
                      initialValue: _cardioSessionDescription
                                  .cardioSession.distance ==
                              null
                          ? null
                          : (_cardioSessionDescription.cardioSession.distance! /
                                  1000)
                              .toString(),
                      decoration:
                          Theme.of(context).textFormFieldDecoration.copyWith(
                                icon: const Icon(AppIcons.ruler),
                                labelText: "Distance (km)",
                              ),
                    ),
                    TextFormField(
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
                      initialValue: _cardioSessionDescription
                          .cardioSession.ascent
                          ?.toString(),
                      decoration:
                          Theme.of(context).textFormFieldDecoration.copyWith(
                                icon: const Icon(AppIcons.trendingUp),
                                labelText: "Ascent (m)",
                              ),
                    ),
                    TextFormField(
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
                      initialValue: _cardioSessionDescription
                          .cardioSession.descent
                          ?.toString(),
                      decoration:
                          Theme.of(context).textFormFieldDecoration.copyWith(
                                icon: const Icon(AppIcons.trendingDown),
                                labelText: "Descent (m)",
                              ),
                    ),
                    _cardioSessionDescription.cardioSession.time == null
                        ? EditTile(
                            leading: AppIcons.timeInterval,
                            child: ActionChip(
                              avatar: const Icon(AppIcons.add),
                              label: const Text("Time"),
                              onPressed: () => setState(() {
                                _cardioSessionDescription.cardioSession.time =
                                    const Duration(minutes: 1);
                              }),
                            ),
                          )
                        : EditTile(
                            leading: AppIcons.timeInterval,
                            caption: "Time",
                            child: Text(
                              _cardioSessionDescription
                                  .cardioSession.time!.formatHms,
                            ),
                            onTap: () async {
                              final duration =
                                  await showScrollableDurationPicker(
                                context: context,
                                initialDuration: _cardioSessionDescription
                                    .cardioSession.time,
                              );
                              if (mounted && duration != null) {
                                setState(
                                  () => _cardioSessionDescription
                                      .cardioSession.time = duration,
                                );
                              }
                            },
                            onCancel: () => setState(() {
                              _cardioSessionDescription.cardioSession.time =
                                  null;
                            }),
                          ),
                    TextFormField(
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
                      initialValue: _cardioSessionDescription
                          .cardioSession.calories
                          ?.toString(),
                      decoration:
                          Theme.of(context).textFormFieldDecoration.copyWith(
                                icon: const Icon(AppIcons.food),
                                labelText: "Calories",
                              ),
                    ),
                    TextFormField(
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
                      initialValue: _cardioSessionDescription
                          .cardioSession.avgCadence
                          ?.toString(),
                      decoration:
                          Theme.of(context).textFormFieldDecoration.copyWith(
                                icon: const Icon(AppIcons.gauge),
                                labelText: "Cadence",
                              ),
                    ),
                    TextFormField(
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
                      initialValue: _cardioSessionDescription
                          .cardioSession.avgHeartRate
                          ?.toString(),
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
