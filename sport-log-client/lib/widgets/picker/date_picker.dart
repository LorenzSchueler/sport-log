import 'package:flutter/material.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';

Future<DateTime?> showDatePickerWithDefaults({
  required BuildContext context,
  required DateTime initialDate,
  bool future = false,
}) async =>
    (await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1970),
      lastDate: future
          ? DateTime.now().add(const Duration(days: 365))
          : DateTime.now(),
    ))
        ?.beginningOfDay();
