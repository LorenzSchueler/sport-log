import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/user_state.dart';
import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/state/page_return.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/widgets/form_widgets/edit_tile.dart';

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

  @override
  void initState() {
    super.initState();
    _metconSessionDescription = widget.metconSessionDescription ??
        MetconSessionDescription(
            metconSession: MetconSession(
                id: randomId(),
                userId: UserState.instance.currentUser!.id,
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
                    userId: UserState.instance.currentUser!.id,
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
                          userId: UserState.instance.currentUser!.id,
                          name: "pullup",
                          description: null,
                          cardio: false,
                          deleted: false,
                          dimension: MovementDimension.reps))
                ],
                hasReference: true));
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
                  leading: const Icon(Icons.crop),
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
              TextFormField(
                decoration: const InputDecoration(
                    icon: Icon(Icons.crop), labelText: "Comments"),
                initialValue: _metconSessionDescription.metconSession.comments,
                style: const TextStyle(height: 1),
                keyboardType: TextInputType.multiline,
                minLines: 1,
                maxLines: 5,
                onFieldSubmitted: (comments) =>
                    _metconSessionDescription.metconSession.comments = comments,
              )
            ],
          ),
        ));
  }
}
