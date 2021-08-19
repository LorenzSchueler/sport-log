
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/models/all.dart';

class EditStrengthSessionPage extends StatefulWidget {
  const EditStrengthSessionPage({
    Key? key,
    StrengthSessionDescription? description,
  }) : initial = description, super(key: key);

  final StrengthSessionDescription? initial;

  @override
  State<StatefulWidget> createState() => _EditStrengthSessionPageState();
}

class _EditStrengthSessionPageState extends State<EditStrengthSessionPage> {

  late StrengthSessionDescription ssd;
  late bool movementInitialized;

  @override
  void initState() {
    super.initState();
    final userId = Api.instance.currentUser!.id;
    ssd = widget.initial ?? StrengthSessionDescription(
      strengthSession: StrengthSession(
          id: randomId(),
          userId: userId,
          datetime: DateTime.now(),
          movementId: Int64(0),
          movementUnit: MovementUnit.reps,
          interval: null,
          comments: null,
          deleted: false
      ),
      strengthSets: [],
      movement: Movement(
          id: Int64(1),
          userId: userId,
          name: "",
          description: null,
          category: MovementCategory.strength,
          deleted: false
      ),
    );
    movementInitialized = widget.initial != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? "New Strength Session" : "EditStrengthSession"),
      ),
      body: Center(child: Text("hallo")),
    );
  }
}
