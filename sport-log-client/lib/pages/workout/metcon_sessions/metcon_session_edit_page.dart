import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/state/page_return.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/form_widgets/edit_tile.dart';
import 'package:sport_log/widgets/form_widgets/metcon_picker.dart';
import 'package:sport_log/widgets/form_widgets/time_form_field.dart';

class MetconSessionEditPage extends StatefulWidget {
  final MetconSessionDescription? metconSessionDescription;
  const MetconSessionEditPage({Key? key, this.metconSessionDescription})
      : super(key: key);

  @override
  State<MetconSessionEditPage> createState() => MetconSessionEditPageState();
}

class MetconSessionEditPageState extends State<MetconSessionEditPage> {
  final _logger = Logger('MetconSessionEditPage');

  late MetconSessionDescription _metconSessionDescription;
  late bool _finished;

  @override
  void initState() {
    super.initState();
    _metconSessionDescription = widget.metconSessionDescription ??
        MetconSessionDescription(
            metconSession: MetconSession(
                id: randomId(),
                userId: Settings.instance.userId!,
                metconId: Int64(1),
                datetime: DateTime.now(),
                time: null,
                rounds: 2,
                reps: 13,
                rx: true,
                comments: "so comments are here",
                deleted: false),
            metconDescription: MetconDescription(
                metcon: Metcon(
                    id: randomId(),
                    userId: Settings.instance.userId!,
                    name: "cindy",
                    metconType: MetconType.forTime,
                    rounds: 3,
                    timecap: const Duration(minutes: 30),
                    description: "my description",
                    deleted: false),
                moves: [
                  MetconMovementDescription(
                      metconMovement: MetconMovement(
                          id: randomId(),
                          metconId: Int64(1),
                          movementId: Int64(1),
                          movementNumber: 1,
                          count: 5,
                          weight: 0,
                          distanceUnit: null,
                          deleted: false),
                      movement: Movement(
                          id: randomId(),
                          userId: Settings.instance.userId!,
                          name: "pullup",
                          description: null,
                          cardio: false,
                          deleted: false,
                          dimension: MovementDimension.reps))
                ],
                hasReference: true));
    _finished = _metconSessionDescription.metconSession.rounds ==
        _metconSessionDescription.metconDescription.metcon.rounds;
  }

  void _saveMetconSession() {
    // TODO save in Db
    Navigator.of(context).pop(ReturnObject(
        action: widget.metconSessionDescription != null
            ? ReturnAction.updated
            : ReturnAction.created,
        payload: _metconSessionDescription));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Edit Metcon Session"), actions: [
          IconButton(
              onPressed: _saveMetconSession, icon: const Icon(Icons.save))
        ]),
        body: Container(
          padding: const EdgeInsets.all(10),
          child: ListView(
            children: [
              EditTile(
                  leading: Icons.crop,
                  caption: "Metcon",
                  child: Text(_metconSessionDescription.metconDescription.name),
                  onTap: () async {
                    MetconDescription? metconDescription =
                        await showMetconPickerDialog(
                      context: context,
                    );
                    if (metconDescription != null) {
                      setState(() {
                        _metconSessionDescription.metconDescription =
                            metconDescription;
                      });
                    }
                    //  set time round and reps accordingly to avoid null values
                  }),
              EditTile(
                  leading: Icons.crop,
                  caption: "Start Time",
                  child: Text(formatDate(
                      _metconSessionDescription.metconSession.datetime)),
                  onTap: () async {
                    DateTime? date = await showDatePicker(
                      context: context,
                      initialDate:
                          (_metconSessionDescription.metconSession.datetime),
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _metconSessionDescription.metconSession.datetime = date;
                      });
                    }
                  }),
              if (_metconSessionDescription
                      .metconDescription.metcon.metconType ==
                  MetconType.forTime)
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text("finished"),
                  SizedBox(
                      height: 20,
                      child: Switch(
                          value: _finished,
                          onChanged: (finished) => setState(() {
                                _finished = finished;
                                if (_finished) {
                                  _metconSessionDescription
                                          .metconSession.rounds =
                                      _metconSessionDescription
                                          .metconDescription.metcon.rounds;
                                  _metconSessionDescription
                                      .metconSession.rounds = 0;
                                  _metconSessionDescription.metconSession.time =
                                      0;
                                } else {
                                  _metconSessionDescription
                                      .metconSession.rounds = 0;
                                  _metconSessionDescription
                                      .metconSession.rounds = 0;
                                }
                              }))),
                ]),
              if (_metconSessionDescription
                          .metconDescription.metcon.metconType ==
                      MetconType.forTime &&
                  _finished)
                TimeFormField.minSec(
                    minutes:
                        _metconSessionDescription.metconSession.time! ~/ 60,
                    seconds: _metconSessionDescription.metconSession.time! % 60,
                    onMinutesSubmitted: (minutes) => setState(() {
                          _metconSessionDescription.metconSession.time =
                              Duration(
                                      minutes: minutes,
                                      seconds: _metconSessionDescription
                                              .metconSession.time! %
                                          60)
                                  .inSeconds;
                        }),
                    onSecondsSubmitted: (seconds) => setState(() {
                          _metconSessionDescription.metconSession.time =
                              Duration(
                                      minutes: _metconSessionDescription
                                              .metconSession.time! ~/
                                          60,
                                      seconds: seconds)
                                  .inSeconds;
                        })),
              if (_metconSessionDescription
                              .metconDescription.metcon.metconType ==
                          MetconType.forTime &&
                      !_finished ||
                  _metconSessionDescription
                          .metconDescription.metcon.metconType ==
                      MetconType.amrap)
                Row(children: [
                  Expanded(
                      child: TextFormField(
                    decoration: const InputDecoration(
                      icon: Icon(Icons.crop),
                      labelText: "Rounds",
                      contentPadding: EdgeInsets.symmetric(vertical: 5),
                    ),
                    initialValue: _metconSessionDescription.metconSession.rounds
                        .toString(),
                    style: const TextStyle(height: 1),
                    keyboardType: TextInputType.number,
                    onFieldSubmitted: (rounds) => setState(() {
                      _metconSessionDescription.metconSession.rounds =
                          int.parse(rounds);
                    }),
                  )),
                  Defaults.sizedBox.horizontal.normal,
                  Expanded(
                      child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Reps",
                      contentPadding: EdgeInsets.symmetric(vertical: 5),
                    ),
                    initialValue:
                        _metconSessionDescription.metconSession.reps.toString(),
                    style: const TextStyle(height: 1),
                    keyboardType: TextInputType.number,
                    onFieldSubmitted: (reps) => setState(() {
                      _metconSessionDescription.metconSession.reps =
                          int.parse(reps);
                    }),
                  )),
                ]),
              EditTile(
                  caption: "Rx",
                  child: SizedBox(
                      height: 20,
                      child: Switch(
                        value: _metconSessionDescription.metconSession.rx,
                        onChanged: (rx) {
                          setState(() {
                            _metconSessionDescription.metconSession.rx = rx;
                          });
                        },
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )),
                  leading: Icons.crop),
              TextFormField(
                decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(vertical: 5),
                    icon: Icon(Icons.crop),
                    labelText: "Comments"),
                initialValue: _metconSessionDescription.metconSession.comments,
                style: const TextStyle(height: 1),
                keyboardType: TextInputType.multiline,
                minLines: 1,
                maxLines: 5,
                onFieldSubmitted: (comments) => setState(() {
                  _metconSessionDescription.metconSession.comments = comments;
                }),
              )
            ],
          ),
        ));
  }
}
