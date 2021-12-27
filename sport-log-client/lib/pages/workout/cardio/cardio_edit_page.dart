import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:sport_log/data_provider/user_state.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/secrets.dart';
import 'package:sport_log/helpers/state/page_return.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/widgets/cardio_type_picker.dart';
import 'package:sport_log/widgets/custom_icons.dart';
import 'package:sport_log/widgets/form_widgets/duration_picker.dart';
import 'package:sport_log/widgets/form_widgets/edit_tile.dart';
import 'package:sport_log/widgets/movement_picker.dart';
import 'package:sport_log/widgets/route_picker.dart';

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
          userId: UserState.instance.currentUser!.id,
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
    int hours = duration.inHours;
    int minutes = duration.inMinutes - 60 * hours;
    int seconds = duration.inSeconds - 60 * minutes - 3600 * hours;

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
                          accessToken: Secrets.mapboxAccessToken,
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
                    leading: const Icon(Icons.sports),
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
                    leading: const Icon(Icons.sports),
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
                    leading: const Icon(Icons.crop),
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
                    leading: const Icon(CustomIcons.route),
                    caption: "Route",
                    child: Text(_cardioSession.routeId.toString()),
                    onTap: () async {
                      Route? route = await showRoutePickerDialog(context,
                          dismissable: true);
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
                  ),
                ),
                Row(
                  children: [
                    SizedBox(
                        width: 70,
                        child: TextFormField(
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          onFieldSubmitted: (newHours) => setState(() {
                            hours = int.parse(newHours);
                            _cardioSession.time =
                                hours * 3600 + minutes * 60 + seconds;
                          }),
                          style: const TextStyle(height: 1),
                          textInputAction: TextInputAction.next,
                          initialValue: hours.toString().padLeft(2, "0"),
                          decoration: const InputDecoration(
                            icon: Icon(CustomIcons.timeInterval),
                          ),
                        )),
                    const Text(":"),
                    SizedBox(
                      width: 30,
                      child: TextFormField(
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        onFieldSubmitted: (newMinutes) => setState(() {
                          minutes = int.parse(newMinutes);
                          _cardioSession.time =
                              hours * 3600 + minutes * 60 + seconds;
                        }),
                        style: const TextStyle(height: 1),
                        textInputAction: TextInputAction.next,
                        initialValue: minutes.toString().padLeft(2, "0"),
                      ),
                    ),
                    const Text(":"),
                    SizedBox(
                      width: 30,
                      child: TextFormField(
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        onFieldSubmitted: (newSeconds) => setState(() {
                          seconds = int.parse(newSeconds);
                          _cardioSession.time =
                              hours * 3600 + minutes * 60 + seconds;
                        }),
                        style: const TextStyle(height: 1),
                        initialValue: seconds.toString().padLeft(2, "0"),
                      ),
                    )
                  ],
                ),
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
                  ),
                ),
              ],
            )));
  }
}
