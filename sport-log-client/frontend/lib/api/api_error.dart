
enum ApiError {
  usernameTaken, unknown, noInternetConnection, loginFailed, notFound
}

extension ToErrorMessage on ApiError {
  String toErrorMessage() {
    switch (this) {
      case ApiError.usernameTaken:
        return "Username is already taken.";
      case ApiError.unknown:
        return "An unknown error occurred.";
      case ApiError.noInternetConnection:
        return "No Internet connection.";
      case ApiError.loginFailed:
        return "Wrong credentials.";
      case ApiError.notFound:
        return "Resource not found.";
    }
  }
}
