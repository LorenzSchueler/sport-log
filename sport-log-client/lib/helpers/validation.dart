import 'logger.dart';

final logger = Logger('VALIDATION');

abstract class Validatable {
  bool isValid();
}

bool validate(bool val, String message) {
  if (!val) {
    logger.w(message);
    return false;
  }
  return true;
}
