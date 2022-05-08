import 'package:flutter/material.dart';
import 'package:sport_log/widgets/picker/date_picker.dart';
import 'package:sport_log/widgets/picker/time_picker.dart';

Future<DateTime?> showDateTimePicker({
  required BuildContext context,
  required DateTime initial,
  bool future = false,
}) async {
  final date = await showDatePickerWithDefaults(
    context: context,
    initialDate: initial,
    future: future,
  );
  if (date != null) {
    final time = await showScrollableTimePicker(
      context: context,
      initialTime: initial,
    );
    if (time != null) {
      return DateTime(date.year, date.month, date.day, time.hour, time.minute);
    }
  }
  return null;
}
