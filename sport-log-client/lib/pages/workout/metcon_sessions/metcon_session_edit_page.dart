import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/page_return.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/app_icons.dart';
import 'package:sport_log/widgets/form_widgets/duration_picker.dart';
import 'package:sport_log/widgets/form_widgets/edit_tile.dart';
import 'package:sport_log/widgets/form_widgets/metcon_picker.dart';

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
            userId: Settings.userId!,
            metconId: Int64(1),
            datetime: DateTime.now(),
            time: null,
            rounds: 2,
            reps: 13,
            rx: true,
            comments: "so comments are here",
            deleted: false,
          ),
          metconDescription: MetconDescription(
            metcon: Metcon(
              id: randomId(),
              userId: Settings.userId!,
              name: "cindy",
              metconType: MetconType.forTime,
              rounds: 3,
              timecap: const Duration(minutes: 30),
              description: "my description",
              deleted: false,
            ),
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
                  deleted: false,
                ),
                movement: Movement(
                  id: randomId(),
                  userId: Settings.userId!,
                  name: "pullup",
                  description: null,
                  cardio: false,
                  deleted: false,
                  dimension: MovementDimension.reps,
                ),
              )
            ],
            hasReference: true,
          ),
        );
    _finished = _metconSessionDescription.metconSession.rounds ==
        _metconSessionDescription.metconDescription.metcon.rounds;
  }

  void _saveMetconSession() {
    // TODO save in Db
    Navigator.pop(
      context,
      ReturnObject(
        action: widget.metconSessionDescription != null
            ? ReturnAction.updated
            : ReturnAction.created,
        payload: _metconSessionDescription,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Metcon Session"),
        actions: [
          IconButton(
            onPressed: _saveMetconSession,
            icon: const Icon(AppIcons.save),
          )
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(10),
        child: ListView(
          children: [
            EditTile(
              leading: AppIcons.notes,
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
              },
            ),
            EditTile(
              leading: AppIcons.calendar,
              caption: "Start Time",
              child: Text(
                formatDate(
                  _metconSessionDescription.metconSession.datetime,
                ),
              ),
              onTap: () async {
                DateTime? date = await showDatePicker(
                  context: context,
                  initialDate: _metconSessionDescription.metconSession.datetime,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _metconSessionDescription.metconSession.datetime = date;
                  });
                }
              },
            ),
            if (_metconSessionDescription.metconDescription.metcon.metconType ==
                MetconType.forTime)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("finished"),
                  SizedBox(
                    height: 20,
                    child: Switch(
                      value: _finished,
                      onChanged: (finished) => setState(() {
                        _finished = finished;
                        if (_finished) {
                          _metconSessionDescription.metconSession.rounds =
                              _metconSessionDescription
                                  .metconDescription.metcon.rounds;
                          _metconSessionDescription.metconSession.rounds = 0;
                          _metconSessionDescription.metconSession.time =
                              const Duration(seconds: 0);
                        } else {
                          _metconSessionDescription.metconSession.rounds = 0;
                          _metconSessionDescription.metconSession.rounds = 0;
                        }
                      }),
                    ),
                  ),
                ],
              ),
            if (_metconSessionDescription.metconDescription.metcon.metconType ==
                    MetconType.forTime &&
                _finished)
              EditTile(
                caption: 'Time',
                child: DurationPicker(
                  setDuration: (d) => setState(
                    () => _metconSessionDescription.metconSession.time = d,
                  ),
                  initialDuration:
                      _metconSessionDescription.metconSession.time!,
                ),
                leading: AppIcons.timeInterval,
              ),
            if (_metconSessionDescription.metconDescription.metcon.metconType ==
                        MetconType.forTime &&
                    !_finished ||
                _metconSessionDescription.metconDescription.metcon.metconType ==
                    MetconType.amrap)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        icon: Icon(AppIcons.repeat),
                        labelText: "Rounds",
                        contentPadding: EdgeInsets.symmetric(vertical: 5),
                      ),
                      initialValue: _metconSessionDescription
                          .metconSession.rounds
                          .toString(),
                      style: const TextStyle(height: 1),
                      keyboardType: TextInputType.number,
                      onChanged: (rounds) => setState(() {
                        _metconSessionDescription.metconSession.rounds =
                            int.parse(rounds);
                      }),
                    ),
                  ),
                  Defaults.sizedBox.horizontal.normal,
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: "Reps",
                        contentPadding: EdgeInsets.symmetric(vertical: 5),
                      ),
                      initialValue: _metconSessionDescription.metconSession.reps
                          .toString(),
                      style: const TextStyle(height: 1),
                      keyboardType: TextInputType.number,
                      onChanged: (reps) => setState(() {
                        _metconSessionDescription.metconSession.reps =
                            int.parse(reps);
                      }),
                    ),
                  ),
                ],
              ),
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
                ),
              ),
              leading: AppIcons.checkBox,
            ),
            TextFormField(
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(vertical: 5),
                icon: Icon(AppIcons.comment),
                labelText: "Comments",
              ),
              initialValue: _metconSessionDescription.metconSession.comments,
              style: const TextStyle(height: 1),
              keyboardType: TextInputType.multiline,
              minLines: 1,
              maxLines: 5,
              onChanged: (comments) => setState(() {
                _metconSessionDescription.metconSession.comments = comments;
              }),
            )
          ],
        ),
      ),
    );
  }
}
