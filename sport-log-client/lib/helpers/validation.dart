import 'logger.dart';

final _logger = Logger('VALIDATION');

abstract class Validatable {
  bool isValid();
}

bool validate(bool val, String message) {
  if (!val) {
    _logger.w(message);
    return false;
  }
  return true;
}
