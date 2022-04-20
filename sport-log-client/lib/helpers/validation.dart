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
    if (url == null || url.isEmpty) {
      return "URL must not be empty.";
    } else if (!isURL(url, protocols: ["http", "https"])) {
      return "URL is invalid.";
    } else {
      return null;
    }
  }

  static String? validateUsername(String? username) {
    if (username == null || username.isEmpty) {
      return "Username must not be empty.";
    } else if (username.contains(':')) {
      return "Username must not contain ':'.";
    } else {
      return null;
    }
  }

  static String? validatePassword(String? password) {
    // ignore: prefer-conditional-expressions
    if (password == null || password.isEmpty) {
      return "Password must not be empty.";
    } else {
      return null;
    }
  }

  static String? validatePassword2(String? password, String? password2) {
    if (password2 == null || password2.isEmpty) {
      return "Password must not be empty.";
    } else if (password != password2) {
      return "Passwords do not match.";
    } else {
      return null;
    }
  }

  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return "Email must not be empty.";
    } else if (!isEmail(email)) {
      return "Email is invalid.";
    } else {
      return null;
    }
  }

  static String? validateHour(String? value) => validateIntGeZero(value);

  static String? validateMinOrSec(String? value) =>
      validateIntGeZeroLtValue(value, 60);

  static String? validateStringNotEmpty(String? value) {
    // ignore: prefer-conditional-expressions
    if (value == null || value.isEmpty) {
      return "Field must not be empty.";
    } else {
      return null;
    }
  }

  static String? validateIntGtZero(String? value) {
    if (value == null || value.isEmpty) {
      return "Field must not be empty.";
    }
    int? intValue = int.tryParse(value);
    if (intValue == null) {
      return "Number is invalid.";
    } else if (intValue <= 0) {
      return "Number must be greater than 0.";
    } else {
      return null;
    }
  }

  static String? validateIntGeZero(String? value) {
    if (value == null || value.isEmpty) {
      return "Field must not be empty.";
    }
    int? intValue = int.tryParse(value);
    if (intValue == null) {
      return "Number is invalid.";
    } else if (intValue < 0) {
      return "Number must be greater or equal than 0.";
    } else {
      return null;
    }
  }

  /// incluse range [lowerBound, upperBound]
  static String? validateIntBetween(
    String? value,
    int lowerBound,
    int upperBound,
  ) {
    if (value == null || value.isEmpty) {
      return "Field must not be empty.";
    }
    int? intValue = int.tryParse(value);
    if (intValue == null) {
      return "Number is invalid.";
    } else if (intValue < lowerBound || intValue > upperBound) {
      return "Number must be between $lowerBound and $upperBound";
    } else {
      return null;
    }
  }

  static String? validateIntGeZeroLtValue(String? value, int upperBound) {
    if (value == null || value.isEmpty) {
      return "Field must not be empty.";
    }
    int? intValue = int.tryParse(value);
    if (intValue == null) {
      return "Number is invalid.";
    } else if (intValue < 0 || intValue >= upperBound) {
      return "Number must be between 0 and ${upperBound - 1}";
    } else {
      return null;
    }
  }

  static String? validateIntGeZeroLeValue(String? value, int upperBound) {
    if (value == null || value.isEmpty) {
      return "Field must not be empty.";
    }
    int? intValue = int.tryParse(value);
    if (intValue == null) {
      return "Number is invalid.";
    } else if (intValue < 0 || intValue > upperBound) {
      return "Number must be between 0 and $upperBound.";
    } else {
      return null;
    }
  }

  static String? validateDoubleGtZero(String? value) {
    if (value == null || value.isEmpty) {
      return "Field must not be empty.";
    }
    double? doubleValue = double.tryParse(value);
    if (doubleValue == null) {
      return "Number is invalid.";
    } else if (doubleValue <= 0) {
      return "Number must be greater than 0.";
    } else {
      return null;
    }
  }
}
