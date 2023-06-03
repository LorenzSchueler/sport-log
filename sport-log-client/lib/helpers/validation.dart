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

extension Case on String {
  bool isUpperCase() {
    final ascii = codeUnitAt(0);
    return ascii >= 65 && ascii <= 90;
  }

  bool isLowerCase() {
    final ascii = codeUnitAt(0);
    return ascii >= 97 && ascii <= 122;
  }

  bool isDigit() {
    final ascii = codeUnitAt(0);
    return ascii >= 48 && ascii <= 57;
  }
}

abstract final class Validator {
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
    } else if (username.length < 2) {
      return "Username must at least be 2 characters long.";
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
    } else if (password.length < 8) {
      return "Password must be at least 8 characters long.";
    } else if (!(password.runes
            .any((c) => String.fromCharCode(c).isLowerCase()) &&
        password.runes.any((c) => String.fromCharCode(c).isUpperCase()) &&
        password.runes.any((c) => String.fromCharCode(c).isDigit()))) {
      return "Password must contain at least one lower case and one upper case character and one number.";
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
    final intValue = int.tryParse(value);
    if (intValue == null) {
      return "Number is invalid.";
    } else if (intValue <= 0) {
      return "Number must be greater than 0.";
    } else {
      return null;
    }
  }

  static String? validateIntGeZero(String? value) =>
      validateIntBetween(value, 0, null);

  /// inclusive range [lowerBound, upperBound]
  static String? validateIntBetween(
    String? value,
    int? lowerBound,
    int? upperBound,
  ) {
    if (value == null || value.isEmpty) {
      return "Field must not be empty.";
    }
    final intValue = int.tryParse(value);
    if (intValue == null) {
      return "Number is invalid.";
    } else if (lowerBound != null && intValue < lowerBound ||
        upperBound != null && intValue > upperBound) {
      if (lowerBound != null && upperBound != null) {
        return "Number must be between $lowerBound and $upperBound";
      } else if (lowerBound != null) {
        return "Number must be greater or equal than $lowerBound";
      } else {
        return "Number must be less or equal than $upperBound";
      }
    } else {
      return null;
    }
  }

  static String? validateDoubleGtZero(String? value) {
    if (value == null || value.isEmpty) {
      return "Field must not be empty.";
    }
    final doubleValue = double.tryParse(value);
    if (doubleValue == null) {
      return "Number is invalid.";
    } else if (doubleValue <= 0) {
      return "Number must be greater than 0.";
    } else {
      return null;
    }
  }

  /// inclusive range [lowerBound, upperBound]
  static String? validateDoubleBetween(
    String? value,
    double? lowerBound,
    double? upperBound,
  ) {
    if (value == null || value.isEmpty) {
      return "Field must not be empty.";
    }
    final intValue = double.tryParse(value);
    if (intValue == null) {
      return "Number is invalid.";
    } else if (lowerBound != null && intValue < lowerBound ||
        upperBound != null && intValue > upperBound) {
      if (lowerBound != null && upperBound != null) {
        return "Number must be between $lowerBound and $upperBound";
      } else if (lowerBound != null) {
        return "Number must be greater or equal than $lowerBound";
      } else {
        return "Number must be less or equal than $upperBound";
      }
    } else {
      return null;
    }
  }
}
