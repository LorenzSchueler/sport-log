
import 'dart:developer';

abstract class Validatable {
  bool isValid();
}

void _logError(String message) {
  log(message, name: 'VALIDATION ERROR');
}

bool validate(bool val, String message) {
  if (!val) {
    _logError(message);
    return false;
  }
  return true;
}
