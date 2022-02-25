import 'package:flutter/material.dart' hide Route;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:sport_log/data_provider/data_providers/all.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/page_return.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/models/cardio/cardio_session_description.dart';
import 'package:sport_log/widgets/form_widgets/cardio_type_picker.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/form_widgets/duration_picker.dart';
import 'package:sport_log/widgets/form_widgets/edit_tile.dart';
import 'package:sport_log/widgets/form_widgets/movement_picker.dart';
import 'package:sport_log/widgets/form_widgets/route_picker.dart';
import 'package:sport_log/widgets/message_dialog.dart';

class CardioEditPage extends StatefulWidget {
  final CardioSessionDescription? cardioSessionDescription;

  const CardioEditPage({Key? key, this.cardioSessionDescription})
      : super(key: key);

  @override
  State<CardioEditPage> createState() => CardioEditPageState();
}

class CardioEditPageState extends State<CardioEditPage> {
  final _logger = Logger('CardioEditPage');
  final _formKey = GlobalKey<FormState>();
  final _dataProvider = CardioSessionDescriptionDataProvider.instance;

  late CardioSessionDescription _cardioSessionDescription;

  @override
  void initState() {
    _cardioSessionDescription = widget.cardioSessionDescription ??
        CardioSessionDescription.defaultValue();
    super.initState();
  }

  Future<void> _saveCardioSession() async {
    final result = widget.cardioSessionDescription != null
        ? await _dataProvider.updateSingle(_cardioSessionDescription)
        : await _dataProvider.createSingle(_cardioSessionDescription);
    if (result) {
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
        text: 'Creating Cardio Session failed.',
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
    late MapboxMapController _sessionMapController;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cardio Edit"),
        actions: [
          IconButton(
            onPressed: _deleteCardioSession,
            icon: const Icon(AppIcons.delete),
          ),
          IconButton(
            onPressed: _formKey.currentContext != null &&
                    _formKey.currentState!.validate()
                ? _saveCardioSession
                : null,
            icon: const Icon(AppIcons.save),
          )
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(10),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_cardioSessionDescription.cardioSession.track != null)
                SizedBox(
                  height: 150,
                  child: MapboxMap(
                    accessToken: Defaults.mapbox.accessToken,
                    styleString: Defaults.mapbox.style.outdoor,
                    initialCameraPosition: CameraPosition(
                      zoom: 13.0,
                      target: _cardioSessionDescription.cardioSession.track ==
                                  null ||
                              _cardioSessionDescription
                                  .cardioSession.track!.isEmpty
                          ? Defaults.mapbox.cameraPosition
                          : _cardioSessionDescription
                              .cardioSession.track!.first.latLng,
                    ),
                    onMapCreated: (MapboxMapController controller) =>
                        _sessionMapController = controller,
                    onStyleLoadedCallback: () {
                      if (_cardioSessionDescription.cardioSession.track !=
                          null) {
                        _sessionMapController.addLine(
                          LineOptions(
                            lineColor: "red",
                            geometry: _cardioSessionDescription
                                .cardioSession.track
                                ?.map((c) => c.latLng)
                                .toList(),
                          ),
                        );
                      }
                      if (_cardioSessionDescription.route != null) {
                        _sessionMapController.addLine(
                          LineOptions(
                            lineColor: "blue",
                            geometry: _cardioSessionDescription.route!.track
                                .map((c) => c.latLng)
                                .toList(),
                          ),
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
                  Movement? movement = await showMovementPickerDialog(
                    context,
                    dismissable: true,
                    cardioOnly: true,
                  );
                  if (movement != null) {
                    setState(() {
                      _cardioSessionDescription.cardioSession.movementId =
                          movement.id;
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
                  CardioType? cardioType = await showCardioTypePickerDialog(
                    context,
                    dismissable: false,
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
                  _cardioSessionDescription
                      .cardioSession.datetime.formatDatetime,
                ),
                onTap: () async {
                  DateTime? datetime = await showDatePicker(
                    context: context,
                    initialDate:
                        _cardioSessionDescription.cardioSession.datetime,
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now(),
                  );
                  TimeOfDay? time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(
                      _cardioSessionDescription.cardioSession.datetime,
                    ),
                  );
                  if (datetime != null && time != null) {
                    datetime = datetime.add(
                      Duration(hours: time.hour, minutes: time.minute),
                    );
                    setState(() {
                      _cardioSessionDescription.cardioSession.datetime =
                          datetime!;
                    });
                  }
                },
              ),
              EditTile(
                leading: AppIcons.route,
                caption: "Route",
                child: Text(
                  _cardioSessionDescription.route != null
                      ? _cardioSessionDescription.route!.name
                      : "none",
                ),
                onTap: () async {
                  Route? route = await showRoutePickerDialog(
                    context: context,
                    dismissable: true,
                  );
                  if (route != null) {
                    setState(() {
                      _cardioSessionDescription.cardioSession.routeId =
                          route.id;
                    });
                  }
                },
              ),
              // TODO add GPX/ GeoJson upload option for track
              TextFormField(
                keyboardType: TextInputType.number,
                onChanged: (distance) => setState(() {
                  _cardioSessionDescription.cardioSession.distance =
                      (double.parse(distance) * 1000).round();
                }),
                style: const TextStyle(height: 1),
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
                style: const TextStyle(height: 1),
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
                style: const TextStyle(height: 1),
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
                child: DurationPicker(
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
                style: const TextStyle(height: 1),
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
                style: const TextStyle(height: 1),
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
                style: const TextStyle(height: 1),
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
                style: const TextStyle(height: 1),
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
