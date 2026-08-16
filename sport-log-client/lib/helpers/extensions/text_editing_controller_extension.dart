import 'package:material_ui/material_ui.dart';

extension TextEditingControllerExtension on TextEditingController {
  void selectAll() {
    selection = TextSelection(baseOffset: 0, extentOffset: text.length);
  }
}
