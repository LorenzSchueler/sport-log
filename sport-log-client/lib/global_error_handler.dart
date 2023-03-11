import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sport_log/app.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/write_to_file.dart';
import 'package:sport_log/widgets/dialogs/dialogs.dart';

class GlobalErrorHandler {
  static final _logger = Logger("GlobalErrorHandler");

  static void run(void Function() function) {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      GlobalErrorHandler._handleError(
        "FlutterError",
        details.exception,
        details.stack,
        details.context,
        details.library,
      );
    };
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      GlobalErrorHandler._handleError("PlatformDispatcher", error, stackTrace);
      return true;
    };
    runZonedGuarded(
      () => function(),
      (error, stackTrace) =>
          GlobalErrorHandler._handleError("runZoneGuarded", error, stackTrace),
    );
  }

  static Future<void> _handleError(
    String caughtBy,
    Object error,
    StackTrace? stackTrace, [
    DiagnosticsNode? diagnosticsNode,
    String? library,
  ]) async {
    final now = DateTime.now();
    final description =
        "time: $now\ncaught by: $caughtBy\ncontext: $diagnosticsNode\nlibrary: $library\n\nerror:\n$error";
    final descriptionAndStack =
        "$description\n\nstack trace:\n$stackTrace\n\n\n";

    final file = await writeToFile(
      content: descriptionAndStack,
      filename: Config.debugMode ? "sport-log(debug)" : "sport-log",
      fileExtension: "log",
      append: true,
    );
    if (file != null) {
      _logger.i("error written to file $file");
    } else {
      _logger.w("writing error logs failed");
    }

    final context = App.globalContext;
    if (context.mounted) {
      await showMessageDialog(
        context: context,
        title: "An error occurred:",
        text: description,
      );
    }
  }
}
