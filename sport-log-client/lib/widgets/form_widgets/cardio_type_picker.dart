import 'package:flutter/material.dart';
import 'package:sport_log/models/cardio/cardio_session.dart';

Future<CardioType?> showCardioTypePickerDialog(
  BuildContext context, {
  bool dismissable = true,
}) async {
  return showDialog<CardioType>(
    builder: (_) => const CardioTypePickerDialog(),
    barrierDismissible: dismissable,
    context: context,
  );
}

class CardioTypePickerDialog extends StatelessWidget {
  const CardioTypePickerDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
        clipBehavior: Clip.antiAlias,
        child: ListView(
          children: [
            ListTile(
              title: Text(CardioType.training.name),
              onTap: () {
                Navigator.of(context).pop(CardioType.training);
              },
            ),
            const Divider(),
            ListTile(
              title: Text(CardioType.activeRecovery.name),
              onTap: () {
                Navigator.of(context).pop(CardioType.activeRecovery);
              },
            ),
            const Divider(),
            ListTile(
              title: Text(CardioType.freetime.name),
              onTap: () {
                Navigator.of(context).pop(CardioType.freetime);
              },
            ),
          ],
        ));
  }
}
