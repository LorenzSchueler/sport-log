import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

void showSimpleSnackBar(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

void showSimpleToast(BuildContext context, String text) {
  Fluttertoast.showToast(
    msg: text,
    backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
    textColor: Theme.of(context).colorScheme.onSurfaceVariant,
  );
}
