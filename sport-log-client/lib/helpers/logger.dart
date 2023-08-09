import 'package:logger/logger.dart' as l;
import 'package:sport_log/config.dart';
import 'package:sport_log/global_error_handler.dart';

export 'package:logger/logger.dart' show Level;

// Log Level policy
// trace: db statements and http requests and responses
// debug: detailed information for automatically invoked actions and for user invoked actions
// info: automatically invoked actions like db setup, sync; no detailed formation
// warning: errors that occur because of missing permissions, primarily writing files which can not use error because that would lead to recursion
// error: uncaught (except in GlobalErrorHandler) exceptions and caught exceptions for which it is not clear why they occurred; recoverable
// fatal: unrecoverable errors

// Log Message Policy
// log messages should not be capitalized and end without dot

void logDebug(Object? message) {
  Logger("logDebug").d(message);
}

class Logger extends l.Logger {
  Logger(String key)
      : super(
          printer: _Printer(key),
          level: Config.instance.minLogLevel,
        );

  /// Log error and invoke [GlobalErrorHandler.handleError]
  @override
  void e(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
    String? caughtBy,
  }) {
    super.e(message, time: time, error: error, stackTrace: stackTrace);
    GlobalErrorHandler.handleError(
      caughtBy ?? "Logger.e",
      "$message: $error",
      stackTrace,
    );
  }

  /// Log error and invoke [GlobalErrorHandler.handleError]
  @override
  void f(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
    String? caughtBy,
  }) {
    super.f(message, time: time, error: error, stackTrace: stackTrace);
    GlobalErrorHandler.handleError(
      caughtBy ?? "Logger.f",
      "$message: $error",
      stackTrace,
    );
  }
}

class InitLogger extends l.Logger {
  InitLogger(String key) : super(printer: _Printer(key));

  /// Log error and invoke [GlobalErrorHandler.handleError].
  @override
  void e(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
    String? caughtBy,
  }) {
    super.e(message, time: time, error: error, stackTrace: stackTrace);
    GlobalErrorHandler.handleError(
      caughtBy ?? "InitLogger.e",
      "$message: $error",
      stackTrace,
    );
  }

  /// Log error and invoke [GlobalErrorHandler.handleError].
  @override
  void f(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
    String? caughtBy,
  }) {
    super.f(message, time: time, error: error, stackTrace: stackTrace);
    GlobalErrorHandler.handleError(
      caughtBy ?? "InitLogger.f",
      "$message: $error",
      stackTrace,
    );
  }
}

class _Printer extends l.PrettyPrinter {
  _Printer(this.key)
      : super(methodCount: 0, errorMethodCount: 5, lineLength: 40);

  final String key;

  @override
  String stringifyMessage(dynamic message) {
    return '[$key] ${super.stringifyMessage(message)}';
  }
}
