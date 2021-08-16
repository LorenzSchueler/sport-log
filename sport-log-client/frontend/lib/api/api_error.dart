
enum ApiError {
  usernameTaken,
  noInternetConnection,
  loginFailed,
  notFound,
  unknown, // unknown status code from server
  unhandled, // unknown request error
  conflict,
  badJson,
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
      case ApiError.unhandled:
        return "Unhandled error occurred.";
      case ApiError.conflict:
        return "Conflict creating resource";
      case ApiError.badJson:
        return "Got bad json from server.";
    }
  }
}
