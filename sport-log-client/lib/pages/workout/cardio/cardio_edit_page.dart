import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:sport_log/data_provider/user_state.dart';
import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/widgets/cardio_type_picker.dart';
import 'package:sport_log/widgets/form_widgets/edit_tile.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Cardio Edit"),
          actions: [
            IconButton(
                onPressed: () => Navigator.of(context)
                    .pop(_cardioSession), // TODO save in DB
                icon: const Icon(Icons.save))
          ],
        ),
        body: Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
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
