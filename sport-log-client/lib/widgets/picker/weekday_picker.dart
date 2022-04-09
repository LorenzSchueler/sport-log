import 'package:flutter/material.dart';
import 'package:sport_log/models/action/weekday.dart';

Future<Weekday?> showWeekdayPicker({
  required BuildContext context,
  bool dismissable = true,
}) async {
  return showDialog<Weekday>(
    builder: (_) => const WeekdayPickerDialog(),
    barrierDismissible: dismissable,
    context: context,
  );
}

class WeekdayPickerDialog extends StatelessWidget {
  const WeekdayPickerDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        itemBuilder: (context, index) => ListTile(
          title: Text(Weekday.values[index].displayName),
          onTap: () {
            Navigator.pop(context, Weekday.values[index]);
          },
        ),
        itemCount: Weekday.values.length,
        separatorBuilder: (context, _) => const Divider(),
      ),
    );
  }
}
