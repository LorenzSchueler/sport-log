import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sport_log/helpers/theme.dart';

void showSimpleSnackBar(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

void showSimpleToast(BuildContext context, String text) {
  Fluttertoast.showToast(
    msg: text,
    backgroundColor: onBackgroundColorOf(context),
    textColor: backgroundColorOf(context),
  );
}
