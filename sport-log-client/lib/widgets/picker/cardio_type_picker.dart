import 'package:flutter/material.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/models/cardio/cardio_session.dart';

Future<CardioType?> showCardioTypePicker({
  required BuildContext context,
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
      child: Padding(
        padding: Defaults.edgeInsets.normal,
        child: ListView.separated(
          itemBuilder: (context, index) => ListTile(
            title: Text(CardioType.values[index].displayName),
            onTap: () {
              Navigator.pop(context, CardioType.values[index]);
            },
          ),
          itemCount: CardioType.values.length,
          separatorBuilder: (context, _) => const Divider(),
          shrinkWrap: true,
        ),
      ),
    );
  }
}
