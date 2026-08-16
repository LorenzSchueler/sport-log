import 'package:fluttertoast/fluttertoast.dart';
import 'package:material_ui/material_ui.dart';

void showSimpleToast(BuildContext context, String text) {
  Fluttertoast.showToast(
    msg: text,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    textColor: Theme.of(context).colorScheme.onSurfaceVariant,
  );
}

void showNoInternetToast(BuildContext context) =>
    showSimpleToast(context, 'No Internet Connection.');
