import 'logger.dart';

export 'interfaces.dart';

final _logger = Logger('VALIDATION');

bool validate(bool val, String message) {
  if (!val) {
    _logger.w(message);
    return false;
  }
  return true;
}
