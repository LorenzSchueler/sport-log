import 'package:material_ui/material_ui.dart';
import 'package:sport_log/app.dart';

void showSimpleSnackBar(String text) => App.scaffoldMessengerKey.currentState
    ?.showSnackBar(SnackBar(content: Text(text)));

void showNoInternetSnackBar() => showSimpleSnackBar('No Internet Connection.');
