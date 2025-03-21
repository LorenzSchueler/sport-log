import 'package:flutter/material.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/widgets/time_spinner.dart';

class TimePickerDialog extends StatefulWidget {
  const TimePickerDialog({
    required this.datetime,
    required this.withSeconds,
    super.key,
  });

  final DateTime? datetime;
  final bool withSeconds;

  @override
  State<TimePickerDialog> createState() => _TimePickerDialogState();
}

class _TimePickerDialogState extends State<TimePickerDialog> {
  DateTime? _datetime;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: TimeSpinner(
        onTimeChange: (datetime) => _datetime = datetime,
        time: widget.datetime,
        isShowSeconds: widget.withSeconds,
        normalTextStyle: Theme.of(
          context,
        ).textTheme.bodyLarge!.copyWith(color: Theme.of(context).disabledColor),
        selectedTextStyle: Theme.of(context).textTheme.bodyLarge!,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _datetime),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

Future<DateTime?> showScrollableTimePicker({
  required BuildContext context,
  required DateTime? initialTime,
  bool withSeconds = false,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  final datetime = await showDialog<DateTime>(
    context: context,
    builder:
        (context) =>
            TimePickerDialog(datetime: initialTime, withSeconds: withSeconds),
  );
  return withSeconds
      ? datetime?.beginningOfSecond()
      : datetime?.beginningOfMinute();
}

Future<Duration?> showScrollableDurationPicker({
  required BuildContext context,
  required Duration? initialDuration,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  final datetime = await showDialog<DateTime>(
    context: context,
    builder:
        (context) => TimePickerDialog(
          datetime: DateTime.now().beginningOfDay().add(
            initialDuration ?? Duration.zero,
          ),
          withSeconds: true,
        ),
  );
  return datetime == null
      ? null
      : Duration(
        hours: datetime.hour,
        minutes: datetime.minute,
        seconds: datetime.second,
      );
}

Future<DateTime?> showDatePickerWithDefaults({
  required BuildContext context,
  required DateTime initialDate,
  bool future = false,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  return (await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime(1970),
    lastDate:
        future ? DateTime.now().add(const Duration(days: 365)) : DateTime.now(),
    locale: const Locale("en", "GB"),
  ))?.beginningOfDay();
}

Future<DateTime?> showDateTimePicker({
  required BuildContext context,
  required DateTime initial,
  bool future = false,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  final date = await showDatePickerWithDefaults(
    context: context,
    initialDate: initial,
    future: future,
  );
  if (context.mounted && date != null) {
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
