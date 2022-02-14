import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/page_return.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/form_widgets/cardio_type_picker.dart';
import 'package:sport_log/widgets/custom_icons.dart';
import 'package:sport_log/widgets/form_widgets/edit_tile.dart';
import 'package:sport_log/widgets/form_widgets/time_form_field.dart';
import 'package:sport_log/widgets/form_widgets/movement_picker.dart';
import 'package:sport_log/widgets/form_widgets/route_picker.dart';

class CardioEditPage extends StatefulWidget {
  final CardioSession? cardioSession;

  const CardioEditPage({Key? key, this.cardioSession}) : super(key: key);

  @override
  State<CardioEditPage> createState() => CardioEditPageState();
}

class CardioEditPageState extends State<CardioEditPage> {
  final _logger = Logger('CardioEditPage');

  late CardioSession _cardioSession;

  @override
  void initState() {
    super.initState();
    _cardioSession = widget.cardioSession ??
        CardioSession(
          id: randomId(),
          userId: Settings.userId!,
          movementId: Int64(1),
          cardioType: CardioType.training,
          datetime: DateTime.now(),
          distance: null,
          ascent: null,
          descent: null,
          time: null,
          calories: null,
          track: null,
          avgCadence: null,
          cadence: null,
          avgHeartRate: null,
          heartRate: null,
          routeId: null,
          comments: null,
          deleted: false,
        );
  }

  void _saveCardioSession() {
    // TODO save in Db
    Navigator.of(context).pop(ReturnObject(
        action: widget.cardioSession != null
            ? ReturnAction.updated
            : ReturnAction.created,
        payload: _cardioSession));
  }

  @override
  Widget build(BuildContext context) {
    Duration duration = Duration(seconds: _cardioSession.time ?? 0);
    int _hours = duration.inHours;
    int _minutes = duration.inMinutes - 60 * _hours;
    int _seconds = duration.inSeconds - 60 * _minutes - 3600 * _hours;

    late MapboxMapController _sessionMapController;

    return Scaffold(
        appBar: AppBar(
          title: const Text("Cardio Edit"),
          actions: [
            IconButton(
                onPressed: _saveCardioSession, icon: const Icon(Icons.save))
          ],
        ),
        body: Container(
            padding: const EdgeInsets.all(10),
            child: ListView(
              children: [
                if (_cardioSession.track != null)
                  SizedBox(
                      height: 150,
                      child: MapboxMap(
                          accessToken: Defaults.mapbox.accessToken,
                          styleString: Defaults.mapbox.style.outdoor,
                          initialCameraPosition: CameraPosition(
                            zoom: 13.0,
                            target: _cardioSession.track!.first.latLng,
                          ),
                          onMapCreated: (MapboxMapController controller) =>
                              _sessionMapController = controller,
                          onStyleLoadedCallback: () {
                            if (_cardioSession.track != null) {
                              _sessionMapController.addLine(LineOptions(
                                  lineColor: "red",
                                  geometry: _cardioSession.track
                                      ?.map((c) => c.latLng)
                                      .toList()));
                            }
                          }
                          // TODO also draw route if available
                          )),
                EditTile(
                    leading: Icons.sports,
                    caption: "Movement",
                    child: Text(_cardioSession.movementId.toString()),
                    onTap: () async {
                      Movement? movement = await showMovementPickerDialog(
                          context,
                          dismissable: true,
                          cardioOnly: true);
                      if (movement != null) {
                        setState(() {
                          _cardioSession.movementId = movement.id;
                        });
                      }
                    }),
                EditTile(
                    leading: Icons.sports,
                    caption: "Cardio Type",
                    child: Text(_cardioSession.cardioType.name),
                    onTap: () async {
                      CardioType? cardioType = await showCardioTypePickerDialog(
                        context,
                        dismissable: false,
                      );
                      if (cardioType != null) {
                        setState(() {
                          _cardioSession.cardioType = cardioType;
                        });
                      }
                    }),
                EditTile(
                    leading: Icons.crop,
                    caption: "Start Time",
                    child: Text(formatDatetime(_cardioSession.datetime)),
                    onTap: () async {
                      DateTime? datetime = await showDatePicker(
                        context: context,
                        initialDate: _cardioSession.datetime,
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now(),
                      );
                      TimeOfDay? time = await showTimePicker(
                          context: context,
                          initialTime:
                              TimeOfDay.fromDateTime(_cardioSession.datetime));
                      if (datetime != null && time != null) {
                        datetime = datetime.add(
                            Duration(hours: time.hour, minutes: time.minute));
                        setState(() {
                          _cardioSession.datetime = datetime!;
                        });
                      }
                    }),
                EditTile(
                    leading: CustomIcons.route,
                    caption: "Route",
                    child: Text(_cardioSession.routeId.toString()),
                    onTap: () async {
                      Route? route = await showRoutePickerDialog(
                          context: context, dismissable: true);
                      if (route != null) {
                        setState(() {
                          _cardioSession.routeId = route.id;
                        });
                      }
                    }),
                // TODO add GPX/ GeoJson upload option for track
                TextFormField(
                  keyboardType: TextInputType.number,
                  onFieldSubmitted: (distance) => setState(() {
                    _cardioSession.distance =
                        (double.parse(distance) * 1000).round();
                  }),
                  style: const TextStyle(height: 1),
                  initialValue: _cardioSession.distance == null
                      ? null
                      : (_cardioSession.distance! / 1000).toString(),
                  decoration: const InputDecoration(
                    icon: Icon(Icons.crop),
                    labelText: "Distance (km)",
                    contentPadding: EdgeInsets.symmetric(vertical: 5),
                  ),
                ),
                TextFormField(
                  keyboardType: TextInputType.number,
                  onFieldSubmitted: (ascent) => setState(() {
                    _cardioSession.ascent = int.parse(ascent);
                  }),
                  style: const TextStyle(height: 1),
                  initialValue: _cardioSession.ascent?.toString(),
                  decoration: const InputDecoration(
                    icon: Icon(Icons.crop),
                    labelText: "Ascent (m)",
                    contentPadding: EdgeInsets.symmetric(vertical: 5),
                  ),
                ),
                TextFormField(
                  keyboardType: TextInputType.number,
                  onFieldSubmitted: (descent) => setState(() {
                    _cardioSession.descent = int.parse(descent);
                  }),
                  style: const TextStyle(height: 1),
                  initialValue: _cardioSession.descent?.toString(),
                  decoration: const InputDecoration(
                    icon: Icon(Icons.crop),
                    labelText: "Descent (m)",
                    contentPadding: EdgeInsets.symmetric(vertical: 5),
                  ),
                ),
                TimeFormField(
                    hours: _hours,
                    minutes: _minutes,
                    seconds: _seconds,
                    onHoursSubmitted: (hours) => setState(() {
                          _hours = hours;
                          _cardioSession.time =
                              _hours * 3600 + _minutes * 60 + _seconds;
                        }),
                    onMinutesSubmitted: (minutes) => setState(() {
                          _minutes = minutes;
                          _cardioSession.time =
                              _hours * 3600 + _minutes * 60 + _seconds;
                        }),
                    onSecondsSubmitted: (seconds) => setState(() {
                          _seconds = seconds;
                          _cardioSession.time =
                              _hours * 3600 + _minutes * 60 + _seconds;
                        })),
                TextFormField(
                  keyboardType: TextInputType.number,
                  onFieldSubmitted: (calories) => setState(() {
                    _cardioSession.calories = int.parse(calories);
                  }),
                  style: const TextStyle(height: 1),
                  initialValue: _cardioSession.calories?.toString(),
                  decoration: const InputDecoration(
                    icon: Icon(Icons.crop),
                    labelText: "Calories",
                    contentPadding: EdgeInsets.symmetric(vertical: 5),
                  ),
                ),
                TextFormField(
                  keyboardType: TextInputType.number,
                  onFieldSubmitted: (avgCadence) => setState(() {
                    _cardioSession.avgCadence = int.parse(avgCadence);
                  }),
                  style: const TextStyle(height: 1),
                  initialValue: _cardioSession.avgCadence?.toString(),
                  decoration: const InputDecoration(
                    icon: Icon(Icons.crop),
                    labelText: "Cadence",
                    contentPadding: EdgeInsets.symmetric(vertical: 5),
                  ),
                ),
                TextFormField(
                  keyboardType: TextInputType.number,
                  onFieldSubmitted: (avgHeartRate) => setState(() {
                    _cardioSession.avgHeartRate = int.parse(avgHeartRate);
                  }),
                  style: const TextStyle(height: 1),
                  initialValue: _cardioSession.avgHeartRate?.toString(),
                  decoration: const InputDecoration(
                    icon: Icon(Icons.crop),
                    labelText: "Heart Rate",
                    contentPadding: EdgeInsets.symmetric(vertical: 5),
                  ),
                ),
                TextFormField(
                  onFieldSubmitted: (comments) => setState(() {
                    _cardioSession.comments = comments;
                  }),
                  style: const TextStyle(height: 1),
                  initialValue: _cardioSession.comments,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.comment),
                    labelText: "Comments",
                    contentPadding: EdgeInsets.symmetric(vertical: 5),
                  ),
                ),
              ],
            )));
  }
}
