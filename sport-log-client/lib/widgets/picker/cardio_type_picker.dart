import 'package:flutter/material.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/models/cardio/cardio_session.dart';

Future<CardioType?> showCardioTypePicker({
  required BuildContext context,
  required CardioType? selectedCardioType,
  bool dismissible = true,
}) async {
  return showDialog<CardioType>(
    builder: (_) =>
        CardioTypePickerDialog(selectedCardioType: selectedCardioType),
    barrierDismissible: dismissible,
    context: context,
  );
}

class CardioTypePickerDialog extends StatelessWidget {
  const CardioTypePickerDialog({required this.selectedCardioType, super.key});

  final CardioType? selectedCardioType;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: Defaults.edgeInsets.normal,
        child: ListView.separated(
          itemBuilder: (context, index) {
            final cardioType = CardioType.values[index];
            return ListTile(
              title: Text("$cardioType"),
              onTap: () => Navigator.pop(context, cardioType),
              selected: cardioType == selectedCardioType,
            );
          },
          itemCount: CardioType.values.length,
          separatorBuilder: (context, _) => const Divider(),
          shrinkWrap: true,
        ),
      ),
    );
  }
}
