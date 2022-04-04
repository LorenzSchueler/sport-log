import 'package:logger/logger.dart' as l;
import 'package:sport_log/config.dart';

export 'package:logger/logger.dart' show Level;

void logInfo(String key, String message) {
  Logger(key).i(message);
}

class Logger extends l.Logger {
  Logger(String key)
      : super(
          printer: _Printer(key),
          level: Config.instance.minLogLevel,
        );
}

class InitLogger extends l.Logger {
  InitLogger(String key) : super(printer: _Printer(key));
}

class _Printer extends l.PrettyPrinter {
  _Printer(this.key)
      : super(methodCount: 0, errorMethodCount: 5, lineLength: 50);

  final String key;

  @override
  String stringifyMessage(dynamic message) {
    return '[$key] ' + super.stringifyMessage(message);
  }
}
