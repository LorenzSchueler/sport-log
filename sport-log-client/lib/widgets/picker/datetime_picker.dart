import 'package:flutter/material.dart';
import 'package:sport_log/widgets/picker/date_picker.dart';
import 'package:sport_log/widgets/picker/time_picker.dart';

Future<DateTime?> showDateTimePicker({
  required BuildContext context,
  required DateTime initial,
}) async {
  final date = await showDatePickerWithDefaults(
    context: context,
    initialDate: initial,
  );
  if (date != null) {
    final time = await showScrollableTimePicker(
      context: context,
      initialTime: initial,
    );
    if (time != null) {
      return date.add(Duration(hours: time.hour, minutes: time.minute));
    }
  }
  return null;
}
