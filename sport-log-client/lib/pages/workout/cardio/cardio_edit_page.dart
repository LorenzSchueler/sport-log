import 'package:flutter/material.dart' hide Route;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/data_provider/data_providers/all.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/extensions/map_controller_extension.dart';
import 'package:sport_log/helpers/page_return.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/models/cardio/cardio_session_description.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/dialogs/approve_dialog.dart';
import 'package:sport_log/widgets/picker/cardio_type_picker.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/input_fields/duration_input.dart';
import 'package:sport_log/widgets/input_fields/edit_tile.dart';
import 'package:sport_log/widgets/picker/datetime_picker.dart';
import 'package:sport_log/widgets/picker/movement_picker.dart';
import 'package:sport_log/widgets/picker/route_picker.dart';
import 'package:sport_log/widgets/dialogs/message_dialog.dart';

class CardioEditPage extends StatefulWidget {
  final CardioSessionDescription? cardioSessionDescription;

  const CardioEditPage({Key? key, this.cardioSessionDescription})
      : super(key: key);

  @override
  State<CardioEditPage> createState() => CardioEditPageState();
}

class CardioEditPageState extends State<CardioEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _dataProvider = CardioSessionDescriptionDataProvider();

  late MapboxMapController _mapController;
  late CardioSessionDescription _cardioSessionDescription;

  @override
  void initState() {
    _cardioSessionDescription = widget.cardioSessionDescription?.clone() ??
        CardioSessionDescription.defaultValue();
    super.initState();
  }

  Future<void> _saveCardioSession() async {
    final result = widget.cardioSessionDescription != null
        ? await _dataProvider.updateSingle(_cardioSessionDescription)
        : await _dataProvider.createSingle(_cardioSessionDescription);
    if (result.isSuccess()) {
      _formKey.currentState!.deactivate();
      Navigator.pop(
        context,
        ReturnObject(
          action: widget.cardioSessionDescription != null
              ? ReturnAction.updated
              : ReturnAction.created,
          payload: _cardioSessionDescription,
        ), // needed for cardio overview page
      );
    } else {
      await showMessageDialog(
        context: context,
        text: 'Creating Cardio Session failed:\n${result.failure}',
      );
    }
  }

  Future<void> _deleteCardioSession() async {
    if (widget.cardioSessionDescription != null) {
      await _dataProvider.deleteSingle(_cardioSessionDescription);
    }
    _formKey.currentState!.deactivate();
    Navigator.pop(
      context,
      ReturnObject(
        action: ReturnAction.deleted,
        payload: _cardioSessionDescription,
      ), // needed for cardio overview page
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.cardioSessionDescription != null
              ? "Edit Cardio Session"
              : "Create Cardio Session",
        ),
        leading: IconButton(
          onPressed: () async {
            final bool? approved = await showDiscardWarningDialog(context);
            if (approved != null && approved) {
              Navigator.pop(context);
            }
          },
          icon: const Icon(AppIcons.arrowBack),
        ),
        actions: [
          IconButton(
            onPressed: _deleteCardioSession,
            icon: const Icon(AppIcons.delete),
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
      body: Container(
        padding: Defaults.edgeInsets.normal,
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_cardioSessionDescription.cardioSession.track != null)
                SizedBox(
                  height: 150,
                  child: MapboxMap(
                    accessToken: Config.instance.accessToken,
                    styleString: Defaults.mapbox.style.outdoor,
                    initialCameraPosition: Settings.lastMapPosition,
                    onMapCreated: (MapboxMapController controller) =>
                        _mapController = controller,
                    onStyleLoadedCallback: () {
                      _mapController.setBounds(
                        _cardioSessionDescription.cardioSession.track,
                        _cardioSessionDescription.route?.track,
                      );
                      if (_cardioSessionDescription.cardioSession.track !=
                          null) {
                        _mapController.addTrackLine(
                          _cardioSessionDescription.cardioSession.track!,
                        );
                      }
                      if (_cardioSessionDescription.route?.track != null) {
                        _mapController.addRouteLine(
                          _cardioSessionDescription.route!.track!,
                        );
                      }
                    },
                  ),
                ),
              EditTile(
                leading: AppIcons.exercise,
                caption: "Movement",
                child: Text(
                  _cardioSessionDescription.movement.name,
                ),
                onTap: () async {
                  Movement? movement = await showMovementPicker(
                    context: context,
                    cardioOnly: true,
                  );
                  if (movement != null) {
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
                  _cardioSessionDescription
                      .cardioSession.cardioType.displayName,
                ),
                onTap: () async {
                  CardioType? cardioType = await showCardioTypePicker(
                    context: context,
                  );
                  if (cardioType != null) {
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
                    initial: _cardioSessionDescription.cardioSession.datetime,
                  );
                  if (datetime != null) {
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
                  Route? route = await showRoutePicker(
                    context: context,
                  );
                  if (route != null) {
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
                onChanged: (distance) => setState(() {
                  _cardioSessionDescription.cardioSession.distance =
                      (double.parse(distance) * 1000).round();
                }),
                initialValue:
                    _cardioSessionDescription.cardioSession.distance == null
                        ? null
                        : (_cardioSessionDescription.cardioSession.distance! /
                                1000)
                            .toString(),
                decoration: const InputDecoration(
                  icon: Icon(AppIcons.ruler),
                  labelText: "Distance (km)",
                  contentPadding: EdgeInsets.symmetric(vertical: 5),
                ),
              ),
              TextFormField(
                keyboardType: TextInputType.number,
                onChanged: (ascent) => setState(() {
                  _cardioSessionDescription.cardioSession.ascent =
                      int.parse(ascent);
                }),
                initialValue:
                    _cardioSessionDescription.cardioSession.ascent?.toString(),
                decoration: const InputDecoration(
                  icon: Icon(AppIcons.trendingUp),
                  labelText: "Ascent (m)",
                  contentPadding: EdgeInsets.symmetric(vertical: 5),
                ),
              ),
              TextFormField(
                keyboardType: TextInputType.number,
                onChanged: (descent) => setState(() {
                  _cardioSessionDescription.cardioSession.descent =
                      int.parse(descent);
                }),
                initialValue:
                    _cardioSessionDescription.cardioSession.descent?.toString(),
                decoration: const InputDecoration(
                  icon: Icon(AppIcons.trendingDown),
                  labelText: "Descent (m)",
                  contentPadding: EdgeInsets.symmetric(vertical: 5),
                ),
              ),
              EditTile(
                caption: 'Time',
                child: DurationInput(
                  setDuration: (d) => setState(
                    () => _cardioSessionDescription.cardioSession.time = d,
                  ),
                  initialDuration: _cardioSessionDescription.cardioSession.time,
                ),
                leading: AppIcons.timeInterval,
              ),
              TextFormField(
                keyboardType: TextInputType.number,
                onChanged: (calories) => setState(() {
                  _cardioSessionDescription.cardioSession.calories =
                      int.parse(calories);
                }),
                initialValue: _cardioSessionDescription.cardioSession.calories
                    ?.toString(),
                decoration: const InputDecoration(
                  icon: Icon(AppIcons.food),
                  labelText: "Calories",
                  contentPadding: EdgeInsets.symmetric(vertical: 5),
                ),
              ),
              TextFormField(
                keyboardType: TextInputType.number,
                onChanged: (avgCadence) => setState(() {
                  _cardioSessionDescription.cardioSession.avgCadence =
                      int.parse(avgCadence);
                }),
                initialValue: _cardioSessionDescription.cardioSession.avgCadence
                    ?.toString(),
                decoration: const InputDecoration(
                  icon: Icon(AppIcons.gauge),
                  labelText: "Cadence",
                  contentPadding: EdgeInsets.symmetric(vertical: 5),
                ),
              ),
              TextFormField(
                keyboardType: TextInputType.number,
                onChanged: (avgHeartRate) => setState(() {
                  _cardioSessionDescription.cardioSession.avgHeartRate =
                      int.parse(avgHeartRate);
                }),
                initialValue: _cardioSessionDescription
                    .cardioSession.avgHeartRate
                    ?.toString(),
                decoration: const InputDecoration(
                  icon: Icon(AppIcons.heartbeat),
                  labelText: "Heart Rate",
                  contentPadding: EdgeInsets.symmetric(vertical: 5),
                ),
              ),
              TextFormField(
                onChanged: (comments) => setState(() {
                  _cardioSessionDescription.cardioSession.comments = comments;
                }),
                initialValue: _cardioSessionDescription.cardioSession.comments,
                decoration: const InputDecoration(
                  icon: Icon(AppIcons.comment),
                  labelText: "Comments",
                  contentPadding: EdgeInsets.symmetric(vertical: 5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
