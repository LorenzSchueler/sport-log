import 'package:flutter/material.dart';

Future<DateTime?> showDatePickerWithDefaults({
  required BuildContext context,
  required DateTime initialDate,
}) =>
    showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
    );
