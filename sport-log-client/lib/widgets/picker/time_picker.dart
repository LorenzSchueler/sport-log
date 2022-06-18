import 'package:flutter/material.dart';
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';

Future<DateTime?> showScrollableTimePicker({
  required BuildContext context,
  required DateTime? initialTime,
  bool withSeconds = false,
}) async {
  final datetime = await showDialog<DateTime>(
    context: context,
    builder: (context) =>
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
  final datetime = await showDialog<DateTime>(
    context: context,
    builder: (context) => TimePickerDialog(
      datetime:
          DateTime.now().beginningOfDay().add(initialDuration ?? Duration.zero),
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
      content: TimePickerSpinner(
        time: widget.datetime,
        onTimeChange: (datetime) => _datetime = datetime,
        normalTextStyle: Theme.of(context)
            .textTheme
            .headline5!
            .copyWith(color: Theme.of(context).disabledColor),
        highlightedTextStyle: Theme.of(context).textTheme.headline5,
        isForce2Digits: true,
        isShowSeconds: widget.withSeconds,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _datetime),
          child: const Text('OK'),
        )
      ],
    );
  }
}
