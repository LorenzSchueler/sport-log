import 'package:flutter/material.dart';

extension TextEditingControllerExtension on TextEditingController {
  void selectAll() {
    selection = TextSelection(baseOffset: 0, extentOffset: text.length);
  }
}
