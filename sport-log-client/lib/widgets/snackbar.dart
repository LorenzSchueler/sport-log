import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

void showSimpleToast(BuildContext context, String text) {
  Fluttertoast.showToast(
    msg: text,
    backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
    textColor: Theme.of(context).colorScheme.onSurfaceVariant,
  );
}
