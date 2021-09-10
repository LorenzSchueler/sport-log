import 'package:logger/logger.dart' as l;

class Logger extends l.Logger {
  Logger(String key)
      : super(
          printer: _Printer(key),
        );
}

class _Printer extends l.PrettyPrinter {
  _Printer(this.key) : super(methodCount: 0);

  final String key;

  @override
  String stringifyMessage(dynamic message) {
    return '[$key] ' + super.stringifyMessage(message);
  }
}