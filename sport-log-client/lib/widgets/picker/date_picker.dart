import 'package:flutter/material.dart';

Future<DateTime?> showDatePickerWithDefaults({
  required BuildContext context,
  required DateTime initialDate,
  bool future = false,
}) =>
    showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1970),
      lastDate: future
          ? DateTime.now().add(const Duration(days: 365))
          : DateTime.now(),
    );
