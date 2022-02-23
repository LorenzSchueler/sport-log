import 'package:sport_log/helpers/logger.dart';
import 'package:validators/validators.dart';

final _logger = Logger('VALIDATION');

bool validate(bool val, String message) {
  if (!val) {
    _logger.w(message);
    return false;
  }
  return true;
}

class Validator {
  Validator._();

  static String? validateUrl(String? url) {
    if (url != null && url.isEmpty) {
      return "URL must not be empty.";
    } else if (url != null && !isURL(url, protocols: ["http", "https"])) {
      return "URL is not valid.";
    } else {
      return null;
    }
  }

  static String? validateUsername(String? username) {
    if (username != null && username.isEmpty) {
      return "Username must not be empty.";
    } else if (username != null && username.contains(':')) {
      return "Username must not contain ':'.";
    } else {
      return null;
    }
  }

  static String? validatePassword(String? password) {
    return password != null && password.isEmpty
        ? "Password must not be empty"
        : null;
  }

  static String? validatePassword2(String? password, String? password2) {
    return password != null &&
            password2 != null &&
            password2.isNotEmpty &&
            password == password2
        ? null
        : "Passwords do not match";
  }

  static String? validateEmail(String? email) {
    if (email == null) {
      return null;
    } else {
      if (email.isEmpty) {
        return "Email must not be empty.";
      } else if (!isEmail(email)) {
        return "Input is not a valid email.";
      } else {
        return null;
      }
    }
  }

  static String? validateHour(String? value) {
    if (value == null) return null;
    int? intValue = int.tryParse(value);
    if (intValue == null) {
      return "please enter a valid number";
    } else if (intValue < 0) {
      return "please enter a positive number";
    } else {
      return null;
    }
  }

  static String? validateMinOrSec(String? value) {
    if (value == null) return null;
    int? intValue = int.tryParse(value);
    if (intValue == null) {
      return "please enter a valid number";
    } else if (intValue < 0 || intValue >= 60) {
      return "please enter a number between 0 and 59";
    } else {
      return null;
    }
  }

  static String? validateIntGtZero(String? value) {
    if (value == null) return null;
    int? intValue = int.tryParse(value);
    if (intValue == null) {
      return "please enter a valid number";
    } else if (intValue <= 0) {
      return "please enter a number greater than 0";
    } else {
      return null;
    }
  }
}
