import 'package:flutter/material.dart';
import 'package:sport_log/defaults.dart';
import 'package:sport_log/models/action/weekday.dart';

Future<Weekday?> showWeekdayPicker({
  required BuildContext context,
  required Weekday? selectedWeekday,
  bool dismissible = true,
}) async {
  return showDialog<Weekday>(
    builder: (_) => WeekdayPickerDialog(selectedWeekday: selectedWeekday),
    barrierDismissible: dismissible,
    context: context,
  );
}

class WeekdayPickerDialog extends StatelessWidget {
  const WeekdayPickerDialog({required this.selectedWeekday, super.key});

  final Weekday? selectedWeekday;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: Defaults.edgeInsets.normal,
        child: ListView.separated(
          itemBuilder: (context, index) {
            final weekday = Weekday.values[index];
            return ListTile(
              title: Text("$weekday"),
              onTap: () => Navigator.pop(context, weekday),
              selected: weekday == selectedWeekday,
            );
          },
          itemCount: Weekday.values.length,
          separatorBuilder: (context, _) => const Divider(),
          shrinkWrap: true,
        ),
      ),
    );
  }
}
