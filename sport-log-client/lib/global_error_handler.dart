import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
      handleError(
        "FlutterError",
        details.exception,
        details.stack,
        details.context,
        details.library,
      );
    };
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      handleError("PlatformDispatcher", error, stackTrace);
      return true;
    };
    runZonedGuarded(
      () => function(),
      (error, stackTrace) => handleError("runZoneGuarded", error, stackTrace),
    );
  }

  /// Gets called either by [GlobalErrorHandler.run] or when logging with log level [Level.error] or [Level.fatal] in [Logger] and [InitLogger].
  /// To avoid recursion [handleError] should not log with either of those log levels.
  static Future<void> handleError(
    String caughtBy,
    Object? error,
    StackTrace? stackTrace, [
    DiagnosticsNode? diagnosticsNode,
    String? library,
  ]) async {
    if (error is PlatformException &&
        error.message != null &&
        error.message!.contains(
          "Attempt to read from field 'float S1.c.c' on a null object reference in method 'boolean S1.d.c()'",
        )) {
      return;
    }

    final description =
        "git ref: ${Config.gitRef}\n"
        "time: ${DateTime.now()}\n"
        "caught by: $caughtBy\n"
        "context: $diagnosticsNode\n"
        "library: $library\n\n"
        "error:\n$error";
    final descriptionAndStack =
        "$description\n\n"
        "stack trace:\n$stackTrace\n\n\n";

    final file = await writeToFile(
      content: descriptionAndStack,
      filename: Config.debugMode ? "sport-log-debug" : "sport-log",
      fileExtension: "log",
      append: true,
    );
    if (file.isOk) {
      _logger.i("error written to file ${file.ok}");
    } else {
      _logger.w("writing error logs failed");
    }

    final context = App.globalContextOptional;
    if (context != null && context.mounted) {
      await showMessageDialog(
        context: context,
        title: "An Error Occurred",
        text: description,
      );
    }
  }
}
